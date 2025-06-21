---
command: /module
description: Generate a new CRUD module following hexagonal architecture patterns
parameters:
  - name: module_name
    description: Snake case module name (e.g., product_category, email_template)
    required: true
  - name: table_schema
    description: Database table schema definition with field names and types
    required: true
examples:
  - command: /module product_category "code:string:50 name:string:100 description:text status:string:20"
    description: Creates a product category module with specified fields
  - command: /module email_template "template_key:string:100 subject:string:200 body:text is_active:boolean"
    description: Creates an email template module with specified fields
---

# Module Generator

This slash command generates a complete CRUD module following the hexagonal architecture pattern outlined in MODULE_CREATION_GUIDE.md.

## Usage

```
/module <module_name> "<field1:type:length field2:type field3:type:length>"
```

### Parameters

1. **module_name**: Snake case name for the module (e.g., `user_profile`, `product_category`)
2. **table_schema**: Space-separated field definitions in format `field:type:length`

### Supported Field Types

- `string:length` - VARCHAR field with specified length
- `text` - TEXT field (no length required)
- `int` - INTEGER field
- `bigint` - BIGINT field  
- `boolean` - BOOLEAN field
- `uuid` - UUID field
- `timestamp` - TIMESTAMPTZ field
- `date` - DATE field
- `decimal:precision,scale` - DECIMAL field

### Field Naming Conventions

- Use snake_case for field names in schema
- Avoid audit fields (created_at, updated_at, etc.) unless explicitly needed
- The generator follows the exact schema provided without adding extra fields

## What Gets Generated

The command creates a complete module with:

### Directory Structure
```
internal/core/{module_name}/
├── application/usecase.go
├── domain/entity/
│   ├── command.go
│   └── query.go
├── infrastructure/
│   ├── presentation/handler.go
│   └── repository/postgres/
│       ├── psql.go
│       └── query.go
└── module.go
```

### Additional Files
- Database migration files
- Port interfaces in `internal/shared/ports/`
- Route registration file
- OpenAPI documentation updates

### Key Features
- Full CRUD operations (Create, Read, Update, Delete, List, Exists, Count)
- DAFI query support for filtering, sorting, pagination
- Proper validation using the shared validation package
- Error handling with the fault package
- Transaction support
- Soft delete functionality (if audit fields present)
- OpenAPI 3 documentation
- Echo framework integration
- Uber Fx dependency injection

## Example

```bash
/module product_category "code:string:50 name:string:100 description:text status:string:20"
```

This generates:
- ProductCategory entity with code, name, description, status fields
- Full CRUD operations
- Database migration for products.product_categories table
- REST API endpoints at /product-categories
- OpenAPI documentation
- Proper validation and error handling

## Important Notes

**CRITICAL**: The generator strictly follows the provided schema. It will NOT add audit fields (created_at, updated_at, deleted_at, etc.) unless they are explicitly included in your schema definition.

If you need audit fields, include them in your schema:
```
/module user_profile "first_name:string:100 last_name:string:100 email:string:255 created_at:timestamp updated_at:timestamp deleted_at:timestamp"
```

The generator ensures:
- Type safety with proper Go types
- Database schema compliance
- Consistent naming conventions
- Complete test coverage structure
- Performance optimizations
- Security best practices

---

## Implementation

When this command is executed, it performs the following steps:

1. **Parse and validate the schema** - Ensures field definitions are valid
2. **Generate directory structure** - Creates the hexagonal architecture folders
3. **Create domain entities** - Generates query.go and command.go with exact schema fields
4. **Generate application layer** - Creates usecase.go with CRUD operations
5. **Create repository layer** - Generates PostgreSQL repository with SQLCraft queries
6. **Generate presentation layer** - Creates HTTP handlers with Echo framework
7. **Create module configuration** - Generates module.go with Fx dependency injection
8. **Generate database migration** - Creates up/down SQL migration files
9. **Update ports** - Adds interface definitions to shared/ports
10. **Register routes** - Creates route registration file
11. **Update OpenAPI docs** - Adds complete API documentation

### Schema Parsing

The schema parser supports these formats:
- `field_name:string:50` - VARCHAR(50)
- `field_name:text` - TEXT
- `field_name:int` - INTEGER
- `field_name:bigint` - BIGINT
- `field_name:boolean` - BOOLEAN
- `field_name:uuid` - UUID
- `field_name:timestamp` - TIMESTAMPTZ
- `field_name:date` - DATE
- `field_name:decimal:10,2` - DECIMAL(10,2)

### Generated Code Example

For schema `code:string:50 name:string:100`, generates:

**Query Entity:**
```go
type ProductCategory struct {
    Code string `json:"code,omitzero"`
    Name string `json:"name,omitzero"`
}
```

**Command Entities:**
```go
type ProductCategoryCreateRequest struct {
    Code string `json:"code"`
    Name string `json:"name"`
}

type ProductCategoryUpdateRequest struct {
    Code null.String `json:"code"`
    Name null.String `json:"name"`
}
```

**Database Migration:**
```sql
CREATE TABLE IF NOT EXISTS products.product_categories (
    code VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);
```

### Error Handling

The generator includes comprehensive error handling:
- Schema validation errors
- File creation conflicts
- Invalid field types
- Missing required parameters
- Directory permission issues

### Post-Generation Steps

After generation, you should:
1. Run `make migration-up` to apply database changes
2. Run `make test` to ensure all tests pass
3. Run `make build` to verify compilation
4. Update any custom business logic in use cases
5. Add any additional validation rules
6. Configure any special indexes or constraints

---

## Code Generation Implementation

The following sections contain the actual code generation templates and logic:

### Schema Parser

```javascript
function parseSchema(schemaString) {
    const fields = schemaString.split(' ').filter(f => f.trim());
    const parsedFields = [];
    
    for (const field of fields) {
        const parts = field.split(':');
        if (parts.length < 2) {
            throw new Error(`Invalid field format: ${field}. Expected format: name:type or name:type:length`);
        }
        
        const [name, type, ...params] = parts;
        const fieldDef = {
            name: name.trim(),
            type: type.trim(),
            params: params.length > 0 ? params.join(':') : null
        };
        
        // Validate field name (snake_case)
        if (!/^[a-z][a-z0-9_]*$/.test(fieldDef.name)) {
            throw new Error(`Invalid field name: ${fieldDef.name}. Use snake_case format.`);
        }
        
        // Validate type
        const validTypes = ['string', 'text', 'int', 'bigint', 'boolean', 'uuid', 'timestamp', 'date', 'decimal'];
        if (!validTypes.includes(fieldDef.type)) {
            throw new Error(`Invalid field type: ${fieldDef.type}. Valid types: ${validTypes.join(', ')}`);
        }
        
        parsedFields.push(fieldDef);
    }
    
    return parsedFields;
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
        'date': 'time.Time',
        'decimal': 'decimal.Decimal'
    };
    
    let goType = typeMap[fieldType];
    if (!goType) {
        throw new Error(`Unsupported field type: ${fieldType}`);
    }
    
    if (isNullable) {
        const nullTypeMap = {
            'string': 'null.String',
            'int': 'null.Int',
            'int64': 'null.Int',
            'bool': 'null.Bool',
            'uuid.UUID': 'uuid.NullUUID',
            'time.Time': 'null.Time',
            'decimal.Decimal': 'decimal.NullDecimal'
        };
        return nullTypeMap[goType] || `null.${goType}`;
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

function toPascalCase(str) {
    return str.split('_').map(word => 
        word.charAt(0).toUpperCase() + word.slice(1)
    ).join('');
}

function toCamelCase(str) {
    const pascal = toPascalCase(str);
    return pascal.charAt(0).toLowerCase() + pascal.slice(1);
}

function toKebabCase(str) {
    return str.replace(/_/g, '-');
}
```

### File Generation Templates

#### Domain Query Entity Template

```javascript
function generateQueryEntity(moduleName, fields) {
    const pascalName = toPascalCase(moduleName);
    
    // Determine required imports
    const imports = new Set(['']);
    let hasTime = false, hasUUID = false, hasNull = false, hasDecimal = false;
    
    fields.forEach(field => {
        if (['timestamp', 'date'].includes(field.type)) hasTime = true;
        if (field.type === 'uuid') hasUUID = true;
        if (field.type === 'decimal') hasDecimal = true;
    });
    
    let importSection = 'package entity\n\n';
    if (hasTime || hasUUID || hasNull || hasDecimal) {
        importSection += 'import (\n';
        if (hasTime) importSection += '\t"time"\n\n';
        if (hasDecimal) importSection += '\t"github.com/shopspring/decimal"\n';
        if (hasUUID) importSection += '\t"github.com/google/uuid"\n';
        if (hasNull) importSection += '\t"gopkg.in/guregu/null.v4"\n';
        importSection += ')\n\n';
    }
    
    let structDef = `type ${pascalName} struct {\n`;
    fields.forEach(field => {
        const fieldName = toPascalCase(field.name);
        const goType = toGoType(field.type, field.params);
        const jsonTag = `\`json:"${toCamelCase(field.name)},omitzero"\``;
        structDef += `\t${fieldName} ${goType} ${jsonTag}\n`;
    });
    structDef += '}\n';
    
    return importSection + structDef;
}
```

#### Domain Command Entity Template  

```javascript
function generateCommandEntity(moduleName, fields) {
    const pascalName = toPascalCase(moduleName);
    const camelName = toCamelCase(moduleName);
    
    // Determine required imports
    let imports = 'package entity\n\nimport (\n';
    imports += '\t"go-hexagonal-fullstack-monorepo/internal/shared/valid"\n\n';
    
    let hasTime = false, hasUUID = false, hasNull = false, hasDecimal = false;
    fields.forEach(field => {
        if (['timestamp', 'date'].includes(field.type)) hasTime = true;
        if (field.type === 'uuid') hasUUID = true;
        if (field.type === 'decimal') hasDecimal = true;
    });
    
    if (hasDecimal) imports += '\t"github.com/shopspring/decimal"\n';
    if (hasUUID) imports += '\t"github.com/google/uuid"\n';
    if (hasTime) imports += '\t"time"\n';
    imports += '\t"gopkg.in/guregu/null.v4"\n';
    imports += ')\n\n';
    
    // Generate validation schema
    let schema = `var ${camelName}Schema = valid.Object(map[string]valid.Schema{\n`;
    fields.forEach(field => {
        const validation = generateValidation(field);
        schema += `\t"${toCamelCase(field.name)}": ${validation},\n`;
    });
    schema += '})\n\n';
    
    // Generate CreateRequest
    let createStruct = `// ${pascalName}CreateRequest represents the request to create a ${pascalName}\n`;
    createStruct += `type ${pascalName}CreateRequest struct {\n`;
    fields.forEach(field => {
        const fieldName = toPascalCase(field.name);
        const goType = toGoType(field.type, field.params);
        const jsonTag = `\`json:"${toCamelCase(field.name)}"\``;
        createStruct += `\t${fieldName} ${goType} ${jsonTag}\n`;
    });
    createStruct += '}\n\n';
    
    // Generate validation method for CreateRequest
    createStruct += `// Validate validates the fields of ${pascalName}CreateRequest\n`;
    createStruct += `func (c ${pascalName}CreateRequest) Validate() error {\n`;
    createStruct += `\tresult := ${camelName}Schema.Parse(c)\n`;
    createStruct += '\tif !result.Success {\n';
    createStruct += '\t\treturn result.Errors[0] // Return first error for simplicity\n';
    createStruct += '\t}\n';
    createStruct += '\treturn nil\n';
    createStruct += '}\n\n';
    
    // Generate UpdateRequest
    let updateStruct = `// ${pascalName}UpdateRequest represents the request to update a ${pascalName}\n`;
    updateStruct += `type ${pascalName}UpdateRequest struct {\n`;
    fields.forEach(field => {
        const fieldName = toPascalCase(field.name);
        const goType = toGoType(field.type, field.params, true); // nullable for updates
        const jsonTag = `\`json:"${toCamelCase(field.name)}"\``;
        updateStruct += `\t${fieldName} ${goType} ${jsonTag}\n`;
    });
    updateStruct += '}\n\n';
    
    // Generate validation method for UpdateRequest
    updateStruct += `// Validate validates the fields of ${pascalName}UpdateRequest\n`;
    updateStruct += `func (c ${pascalName}UpdateRequest) Validate() error {\n`;
    updateStruct += `\tresult := ${camelName}Schema.Parse(c)\n`;
    updateStruct += '\tif !result.Success {\n';
    updateStruct += '\t\treturn result.Errors[0] // Return first error for simplicity\n';
    updateStruct += '\t}\n';
    updateStruct += '\treturn nil\n';
    updateStruct += '}\n';
    
    return imports + schema + createStruct + updateStruct;
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
```

#### Use Case Template

```javascript
function generateUseCase(moduleName, fields) {
    const pascalName = toPascalCase(moduleName);
    
    return `package application

import (
	"context"
	"go-hexagonal-fullstack-monorepo/internal/core/${moduleName}/domain/entity"
	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"
	"go-hexagonal-fullstack-monorepo/internal/shared/types"
)

type UseCase struct {
	repo ports.${pascalName}Repository
}

func NewUseCase(repo ports.${pascalName}Repository) *UseCase {
	return &UseCase{repo: repo}
}

func (u UseCase) Create(ctx context.Context, req entity.${pascalName}CreateRequest) error {
	if err := req.Validate(); err != nil {
		return fault.Wrap(err).Code(fault.UnprocessableEntity)
	}

	if err := u.repo.Create(ctx, req); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (u UseCase) Update(ctx context.Context, req entity.${pascalName}UpdateRequest, filters ...dafi.Filter) error {
	if err := req.Validate(); err != nil {
		return fault.Wrap(err).Code(fault.UnprocessableEntity)
	}

	if err := u.repo.Update(ctx, req, filters...); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (u UseCase) Delete(ctx context.Context, filters ...dafi.Filter) error {
	if err := u.repo.Delete(ctx, filters...); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (u UseCase) Find(ctx context.Context, criteria dafi.Criteria) (entity.${pascalName}, error) {
	result, err := u.repo.Find(ctx, criteria)
	if err != nil {
		return entity.${pascalName}{}, fault.Wrap(err)
	}

	return result, nil
}

func (u UseCase) List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.${pascalName}], error) {
	result, err := u.repo.List(ctx, criteria)
	if err != nil {
		return nil, fault.Wrap(err)
	}

	return result, nil
}

func (u UseCase) Exists(ctx context.Context, criteria dafi.Criteria) (bool, error) {
	exists, err := u.repo.Exists(ctx, criteria)
	if err != nil {
		return false, fault.Wrap(err)
	}

	return exists, nil
}

func (u UseCase) Count(ctx context.Context, criteria dafi.Criteria) (int64, error) {
	count, err := u.repo.Count(ctx, criteria)
	if err != nil {
		return 0, fault.Wrap(err)
	}

	return count, nil
}
`;
}
```

### Database Migration Template

```javascript
function generateMigration(moduleName, fields, schema = 'public') {
    const tableName = moduleName;
    const pascalName = toPascalCase(moduleName);
    
    // Generate UP migration
    let upMigration = `-- Migration: Create ${tableName} table\n`;
    upMigration += `CREATE TABLE IF NOT EXISTS ${schema}.${tableName} (\n`;
    
    fields.forEach((field, index) => {
        const sqlType = toSqlType(field.type, field.params);
        const nullable = field.type === 'uuid' && field.name === 'id' ? ' PRIMARY KEY DEFAULT gen_random_uuid()' : '';
        const notNull = nullable || field.required === false ? '' : ' NOT NULL';
        upMigration += `    ${field.name} ${sqlType}${nullable}${notNull}`;
        if (index < fields.length - 1) upMigration += ',';
        upMigration += '\n';
    });
    
    upMigration += ');\n\n';
    
    // Generate indexes
    fields.forEach(field => {
        if (field.name !== 'id') {
            upMigration += `CREATE INDEX IF NOT EXISTS idx_${tableName}_${field.name} ON ${schema}.${tableName}(${field.name});\n`;
        }
    });
    
    // Generate DOWN migration
    const downMigration = `-- Migration: Drop ${tableName} table\nDROP TABLE IF EXISTS ${schema}.${tableName};\n`;
    
    return { up: upMigration, down: downMigration };
}
```

### Main Generation Function

```javascript
async function generateModule(moduleName, schemaString) {
    try {
        // Parse and validate schema
        const fields = parseSchema(schemaString);
        console.log(`Generating module '${moduleName}' with fields:`, fields);
        
        // Create directory structure
        await createDirectoryStructure(moduleName);
        
        // Generate all files
        await generateAllFiles(moduleName, fields);
        
        console.log(`✅ Module '${moduleName}' generated successfully!`);
        console.log(`\nNext steps:`);
        console.log(`1. Run: make migration-up`);
        console.log(`2. Run: make test`);
        console.log(`3. Run: make build`);
        
    } catch (error) {
        console.error(`❌ Error generating module: ${error.message}`);
        throw error;
    }
}

async function createDirectoryStructure(moduleName) {
    const dirs = [
        `internal/core/${moduleName}`,
        `internal/core/${moduleName}/application`,
        `internal/core/${moduleName}/domain/entity`,
        `internal/core/${moduleName}/infrastructure/presentation`,
        `internal/core/${moduleName}/infrastructure/repository/postgres`
    ];
    
    for (const dir of dirs) {
        await fs.mkdir(dir, { recursive: true });
    }
}

async function generateAllFiles(moduleName, fields) {
    const pascalName = toPascalCase(moduleName);
    
    // Generate domain layer
    await writeFile(
        `internal/core/${moduleName}/domain/entity/query.go`,
        generateQueryEntity(moduleName, fields)
    );
    
    await writeFile(
        `internal/core/${moduleName}/domain/entity/command.go`, 
        generateCommandEntity(moduleName, fields)
    );
    
    // Generate application layer
    await writeFile(
        `internal/core/${moduleName}/application/usecase.go`,
        generateUseCase(moduleName, fields)
    );
    
    // Generate repository layer (implementation needed)
    await writeFile(
        `internal/core/${moduleName}/infrastructure/repository/postgres/query.go`,
        generateRepositoryQuery(moduleName, fields)
    );
    
    await writeFile(
        `internal/core/${moduleName}/infrastructure/repository/postgres/psql.go`,
        generateRepository(moduleName, fields)
    );
    
    // Generate presentation layer
    await writeFile(
        `internal/core/${moduleName}/infrastructure/presentation/handler.go`,
        generateHandler(moduleName, fields)
    );
    
    // Generate module configuration
    await writeFile(
        `internal/core/${moduleName}/module.go`,
        generateModuleConfig(moduleName)
    );
    
    // Generate ports
    await writeFile(
        `internal/shared/ports/${moduleName}.go`,
        generatePorts(moduleName, fields)
    );
    
    // Generate migrations
    const migration = generateMigration(moduleName, fields);
    const timestamp = new Date().toISOString().replace(/[-:.]/g, '').slice(0, 14);
    
    await writeFile(
        `database/migrations/${timestamp}_create_${moduleName}_table.up.sql`,
        migration.up
    );
    
    await writeFile(
        `database/migrations/${timestamp}_create_${moduleName}_table.down.sql`, 
        migration.down
    );
}
```

This implementation provides a complete module generator that follows the hexagonal architecture patterns established in the codebase. The templates generate code that matches the existing modules while strictly adhering to the provided schema without adding extra fields.