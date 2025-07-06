---
description: Generate a new CRUD module by inspecting an existing database table
allowed-tools: [Write, Read, Bash, Glob, LS]
---

# Generate Hexagonal Architecture Module

Generate a complete CRUD module following the hexagonal architecture pattern by analyzing an existing database table schema.

## Usage

`/project:module <table_name>`

### Parameters

- **table_name**: Database table name (with optional schema prefix, e.g., `users`, `auth.users`, `products.categories`)

The command will:
1. Connect to the PostgreSQL database
2. Inspect the table schema to get column definitions
3. Generate the complete module based on the actual table structure
4. Create all necessary files following hexagonal architecture

### Examples

```bash
/project:module users
/project:module products.categories  
/project:module auth.email_credentials
```

## What Gets Generated

This command creates a complete module with:

### Directory Structure
```
internal/core/{module_name}/
├── application/usecase.go
├── domain/entity/
│   ├── command.go
│   └── query.go
├── infrastructure/
│   ├── presentation/handler.go
│   └── repository/
│       └── postgres.go
└── module.go
```

### Additional Files
- Port interfaces in `internal/shared/ports/{module_name}.go`
- Route registration file in `cmd/api/router/{module_name}_routes.go`

### Key Features
- Full CRUD operations using standard repository patterns
- DAFI system integration for filtering, sorting, pagination
- Proper validation using the shared validation package
- Error handling with the fault package
- Transaction support via RepositoryTx interface
- Smart delete handling:
  - Soft delete functionality (if `deleted_at`/`deleted_by` columns present)
  - Hard delete functionality (if no soft delete columns)
- OpenAPI 3 documentation
- Echo framework integration
- Uber Fx dependency injection

### CRITICAL ARCHITECTURE REQUIREMENTS

**Repository Pattern:**
- MUST implement `RepositoryTx[T]`, `RepositoryCommand[C, U]`, and `RepositoryQuery[M]` interfaces
- MUST use `ports.Database` and `ports.Transaction` interfaces
- MUST use DAFI `dafi.Criteria` for all query operations
- NO custom query structs with pointers
- NO direct SQL query building outside of repository implementation

**Entity Design:**
- NEVER add decimal imports unless table actually has decimal/numeric columns
- Use `time.Time` for all timestamp/date fields
- Use `null.String`, `null.Time`, etc. for nullable fields
- NO custom response wrapper structs - use `types.List[T]` directly

**Use Case Layer:**
- MUST return entities by value, not pointers (`entity.User`, not `*entity.User`)
- MUST use `dafi.Criteria` for all query operations
- Return `types.List[entity.T]` for list operations
- Return `int64` for count operations

**Handler Layer:**
- MUST use DAFI system for query parameter parsing
- Build `dafi.Criteria` objects from HTTP query parameters
- Use `dafi.Equal`, `dafi.Like`, etc. for filter operations
- Use `dafi.Asc`/`dafi.Desc` for sorting

## Implementation

```javascript
// Parse command arguments
const tableName = $ARGUMENTS.trim();

if (!tableName) {
    throw new Error('Usage: /project:module <table_name>');
}

// Parse table name to extract schema and table
function parseTableName(fullTableName) {
    const parts = fullTableName.split('.');
    if (parts.length === 1) {
        return { schema: 'public', table: parts[0], moduleName: parts[0] };
    } else if (parts.length === 2) {
        return { schema: parts[0], table: parts[1], moduleName: parts[1] };
    } else {
        throw new Error(`Invalid table name format: ${fullTableName}. Use 'table' or 'schema.table'`);
    }
}

// Query database for table schema using PostgreSQL MCP
async function queryTableSchema(schema, table) {
    const query = `
        SELECT 
            column_name,
            data_type,
            character_maximum_length,
            numeric_precision,
            numeric_scale,
            is_nullable,
            column_default
        FROM information_schema.columns 
        WHERE table_schema = '${schema}' 
        AND table_name = '${table}'
        ORDER BY ordinal_position;
    `;
    
    console.log(`🔍 Querying schema for table ${schema}.${table}...`);
    
    // Execute the query using PostgreSQL MCP
    const result = await mcp.postgres.query({ sql: query });
    
    if (!result || result.length === 0) {
        throw new Error(`Table ${schema}.${table} not found or has no columns`);
    }
    
    return result.map(row => ({
        name: row.column_name,
        dataType: row.data_type,
        maxLength: row.character_maximum_length || null,
        precision: row.numeric_precision || null,
        scale: row.numeric_scale || null,
        nullable: row.is_nullable === 'YES',
        defaultValue: row.column_default
    }));
}

// Convert PostgreSQL types to Go types
function postgresTypeToGoType(pgType, maxLength, precision, scale, nullable = false) {
    let goType;
    let params = null;
    
    switch (pgType.toLowerCase()) {
        case 'character varying':
        case 'varchar':
        case 'char':
        case 'character':
            goType = 'string';
            params = maxLength ? maxLength.toString() : '255';
            break;
        case 'text':
            goType = 'text';
            break;
        case 'integer':
        case 'int':
        case 'int4':
            goType = 'int';
            break;
        case 'bigint':
        case 'int8':
            goType = 'bigint';
            break;
        case 'boolean':
        case 'bool':
            goType = 'boolean';
            break;
        case 'uuid':
            goType = 'uuid';
            break;
        case 'timestamp':
        case 'timestamptz':
        case 'timestamp with time zone':
        case 'timestamp without time zone':
            goType = 'timestamp';
            break;
        case 'date':
            goType = 'date';
            break;
        case 'numeric':
        case 'decimal':
            goType = 'decimal';
            if (precision && scale !== null) {
                params = `${precision},${scale}`;
            }
            break;
        default:
            console.warn(`⚠️  Unknown PostgreSQL type '${pgType}', defaulting to string`);
            goType = 'string';
            params = '255';
    }
    
    return {
        type: goType,
        params: params,
        nullable: nullable
    };
}

// Helper functions
function toPascalCase(str) {
    return str.split('_').map(word => 
        word.charAt(0).toUpperCase() + word.slice(1)
    ).join('');
}

function toCamelCase(str) {
    const pascal = toPascalCase(str);
    return pascal.charAt(0).toLowerCase() + pascal.slice(1);
}

function toGoType(fieldType, params, isNullable = false) {
    const typeMap = {
        'string': 'string',
        'text': 'string', 
        'int': 'int',
        'bigint': 'int64',
        'boolean': 'bool',
        'uuid': 'uuid.UUID',
        'timestamp': 'time.Time',
        'date': 'time.Time'
        // NEVER include decimal unless table actually has decimal/numeric columns
    };
    
    let goType = typeMap[fieldType];
    if (!goType) {
        // Default to string for unknown types to avoid import issues
        console.warn(`⚠️  Unknown field type '${fieldType}', defaulting to string`);
        goType = 'string';
    }
    
    if (isNullable) {
        const nullTypeMap = {
            'string': 'null.String',
            'int': 'null.Int',
            'int64': 'null.Int64',
            'bool': 'null.Bool',
            'uuid.UUID': 'uuid.NullUUID',
            'time.Time': 'null.Time'
            // NEVER include decimal unless table actually has decimal/numeric columns
        };
        return nullTypeMap[goType] || `null.String`; // Safe fallback
    }
    
    return goType;
}

function toSqlType(fieldType, params) {
    switch (fieldType) {
        case 'string':
            return params ? `VARCHAR(${params})` : 'VARCHAR(255)';
        case 'text':
            return 'TEXT';
        case 'int':
            return 'INTEGER';
        case 'bigint':
            return 'BIGINT';
        case 'boolean':
            return 'BOOLEAN';
        case 'uuid':
            return 'UUID';
        case 'timestamp':
            return 'TIMESTAMPTZ';
        case 'date':
            return 'DATE';
        case 'decimal':
            return params ? `DECIMAL(${params})` : 'DECIMAL(10,2)';
        default:
            throw new Error(`Unsupported SQL type: ${fieldType}`);
    }
}

function generateValidation(field) {
    switch (field.type) {
        case 'string':
        case 'text':
            let validation = 'valid.String()';
            if (field.params) {
                validation += `.MaxLength(${field.params})`;
            }
            return validation + '.Required()';
        case 'int':
        case 'bigint':
            return 'valid.Number().Required()';
        case 'boolean':
            return 'valid.Boolean().Required()';
        case 'uuid':
            return 'valid.String().UUID().Required()';
        case 'timestamp':
        case 'date':
            return 'valid.String().DateTime().Required()';
        case 'decimal':
            return 'valid.Number().Required()';
        default:
            return 'valid.String().Required()';
    }
}

// Main execution
(async () => {
    const { schema, table, moduleName } = parseTableName(tableName);

    console.log(`🚀 Generating module for table ${schema}.${table}...`);

    // Query the database to get table schema
    const columns = await queryTableSchema(schema, table);

    if (columns.length === 0) {
        throw new Error(`No columns found for table ${schema}.${table}`);
    }

// Convert database columns to field definitions
const fields = columns.map(col => {
    const goTypeInfo = postgresTypeToGoType(col.dataType, col.maxLength, col.precision, col.scale, col.nullable);
    return {
        name: col.name,
        type: goTypeInfo.type,
        params: goTypeInfo.params,
        nullable: goTypeInfo.nullable,
        dbType: col.dataType,
        defaultValue: col.defaultValue
    };
});

// Check for soft delete columns
const hasSoftDelete = fields.some(f => f.name === 'deleted_at') && fields.some(f => f.name === 'deleted_by');

const pascalName = toPascalCase(moduleName);
const camelName = toCamelCase(moduleName);

console.log(`📊 Found ${fields.length} columns:`);
fields.forEach(f => {
    const typeDisplay = f.params ? `${f.type}:${f.params}` : f.type;
    const nullableDisplay = f.nullable ? ' (nullable)' : '';
    console.log(`  - ${f.name}: ${typeDisplay}${nullableDisplay}`);
});

console.log(`🗑️  Delete strategy: ${hasSoftDelete ? 'Soft delete (with DeleteRequest struct)' : 'Hard delete (direct removal)'}`);
console.log(`\n🔧 Generating complete module structure for '${moduleName}'...`);

// TODO: After generating all module files, also complete these CRITICAL steps:
// 1. Update cmd/api/runner.go to add the module to fx.New() 
// 2. Update cmd/api/router/routes.go to register the module routes
// 3. Update RouterParams struct to include the module handler
// Without these steps, the module will not be accessible via HTTP endpoints

// Note: In the actual implementation, use hasSoftDelete to conditionally generate DeleteRequest struct
})().catch(console.error);
```

The module generator will create all necessary files based on the actual database table structure. This ensures perfect alignment between your database schema and the generated Go code.

**Critical Notes**: 
- The generator uses the EXACT table structure found in the database. All columns (including audit fields like created_at, updated_at, deleted_at) will be included if they exist in the table.
- **DeleteRequest structs**: Only generated for tables with soft delete columns (`deleted_at`, `deleted_by`). Tables without these columns use hard delete operations directly.
- **Validation**: Generated based on actual column constraints and types from the database schema.

## Database Connection

The command uses the PostgreSQL MCP integration for database access. Ensure the MCP PostgreSQL server is properly configured and connected to your database containing the target table.

## Post-Generation Steps

After generation, you MUST complete these steps:

### 1. Add Module to Dependency Injection
Update `cmd/api/runner.go` to include the new module:

```go
import (
    "api.system.soluciones-cloud.com/internal/core/{module_name}"
    // ... other imports
)

func Run() {
    app := fx.New(
        localconfig.Module,
        logger.Module,
        postgres.Module,
        {module_name}.Module,  // Add this line
        server.Module,
        fx.Invoke(router.SetAPIRoutes),
    )
}
```

### 2. Register Routes in Router
Update `cmd/api/router/routes.go` to register the module routes:

```go
import (
    "api.system.soluciones-cloud.com/internal/core/{module_name}/infrastructure/presentation"
    // ... other imports
)

type RouterParams struct {
    fx.In
    {ModuleName}Handler *presentation.{ModuleName}Handler  // Add this line
}

func SetAPIRoutes(echoServer *server.EchoServer, params RouterParams) error {
    // Register {module_name} routes
    Register{ModuleName}Routes(echoServer.PublicAPI, params.{ModuleName}Handler)
    
    return nil
}
```

### 3. Update OpenAPI Documentation
Update `cmd/api/docs/openapi.yaml` to include the new module endpoints:

```yaml
paths:
  /api/v1/{module_name}:
    # Add all CRUD endpoints (POST, GET)
  /api/v1/{module_name}/count:
    # Add count endpoint
  /api/v1/{module_name}/{id}:
    # Add single resource endpoints (GET, PUT, DELETE)
  /api/v1/{module_name}/{id}/exists:
    # Add exists endpoint

components:
  schemas:
    {ModuleName}:
      # Add main entity schema
    Create{ModuleName}Request:
      # Add create request schema
    Update{ModuleName}Request:
      # Add update request schema
    Delete{ModuleName}Request:
      # Add delete request schema (only for soft delete)
```

### 4. Verification Steps
1. Run `make test` to ensure all tests pass  
2. Run `make build` to verify compilation
3. Run `make run-api` to test server startup
4. Test API endpoints with curl or Postman
5. Update any custom business logic in use cases
6. Add any additional validation rules
7. Verify OpenAPI documentation is accessible at `/api/v1/docs`

**CRITICAL**: The module will not work until steps 1 and 2 are completed. The generated routes file (`cmd/api/router/{module_name}_routes.go`) is only a helper - the actual registration must be done in the main `routes.go` file.

## Supported PostgreSQL Types

The generator automatically converts these PostgreSQL types:

| PostgreSQL Type | Go Type | Notes |
|---|---|---|
| `varchar(n)`, `char(n)` | `string` | With length validation |
| `text` | `string` | No length limit |
| `integer`, `int4` | `int` | 32-bit integer |
| `bigint`, `int8` | `int64` | 64-bit integer |
| `boolean` | `bool` | Boolean values |
| `uuid` | `uuid.UUID` | UUID type |
| `timestamp`, `timestamptz` | `time.Time` | Timestamp values |
| `date` | `time.Time` | Date-only values |
| `numeric`, `decimal` | `decimal.Decimal` | Decimal numbers |

Nullable columns are automatically converted to `null.*` types for optional fields in update requests.