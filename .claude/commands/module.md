---
description: Generate a new CRUD module following hexagonal architecture patterns
allowed-tools: [Write, Read, Bash, Glob, LS]
---

# Generate Hexagonal Architecture Module

Generate a complete CRUD module following the hexagonal architecture pattern outlined in MODULE_CREATION_GUIDE.md.

## Usage

`/project:module <module_name> "<field1:type:length field2:type field3:type>"`

### Parameters

- **module_name**: Snake case module name (e.g., `product_category`, `email_template`)
- **field_schema**: Space-separated field definitions in format `field:type:length`

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

### Examples

```bash
/project:module product_category "code:string:50 name:string:100 description:text status:string:20"
/project:module email_template "template_key:string:100 subject:string:200 body:text is_active:boolean"
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
│   └── repository/postgres/
│       ├── psql.go
│       └── query.go
└── module.go
```

### Additional Files
- Database migration files in `database/migrations/`
- Port interfaces in `internal/shared/ports/`
- Route registration file in `cmd/api/router/`
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

## Implementation

```javascript
// Parse command arguments
const [moduleName, schemaString] = $ARGUMENTS.split(' ', 2);

if (!moduleName || !schemaString) {
    throw new Error('Usage: /project:module <module_name> "<field1:type:length field2:type>"');
}

// Parse schema
function parseSchema(schemaString) {
    const cleanSchema = schemaString.replace(/['"]/g, '');
    const fields = cleanSchema.split(' ').filter(f => f.trim());
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

// Generate files
const fields = parseSchema(schemaString);
const pascalName = toPascalCase(moduleName);
const camelName = toCamelCase(moduleName);

console.log(`Generating module '${moduleName}' with fields:`, fields.map(f => `${f.name}:${f.type}${f.params ? ':' + f.params : ''}`).join(', '));
```

Let me create the directory structure and generate all the necessary files for the module.

**Critical Note**: The generator strictly follows the provided schema. It will NOT add audit fields (created_at, updated_at, deleted_at, etc.) unless they are explicitly included in your field definition.

If you need audit fields, include them in your schema:
```
/project:module user_profile "first_name:string:100 last_name:string:100 email:string:255 created_at:timestamp updated_at:timestamp deleted_at:timestamp"
```

## Post-Generation Steps

After generation, you should:
1. Run `make migration-up` to apply database changes
2. Run `make test` to ensure all tests pass  
3. Run `make build` to verify compilation
4. Update any custom business logic in use cases
5. Add any additional validation rules
6. Configure any special indexes or constraints