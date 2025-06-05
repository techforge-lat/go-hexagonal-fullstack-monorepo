package valid

import "fmt"

type Language string

const (
	English Language = "en"
	Spanish Language = "es"
)

var currentLanguage = English

func SetLanguage(lang Language) {
	currentLanguage = lang
}

func GetLanguage() Language {
	return currentLanguage
}

type messages struct {
	Required    map[Language]string
	TypeString  map[Language]string
	TypeNumber  map[Language]string
	MinLength   map[Language]string
	MaxLength   map[Language]string
	Pattern     map[Language]string
	Email       map[Language]string
	URL         map[Language]string
	UUID        map[Language]string
	Min         map[Language]string
	Max         map[Language]string
	Integer     map[Language]string
	Positive    map[Language]string
	Negative    map[Language]string
	TypeObject  map[Language]string
	TypeArray   map[Language]string
	MinItems    map[Language]string
	MaxItems    map[Language]string
}

var msgs = messages{
	Required: map[Language]string{
		English: "This field is required",
		Spanish: "Este campo es obligatorio",
	},
	TypeString: map[Language]string{
		English: "This field must be text",
		Spanish: "Este campo debe ser texto",
	},
	TypeNumber: map[Language]string{
		English: "This field must be a number",
		Spanish: "Este campo debe ser un número",
	},
	MinLength: map[Language]string{
		English: "Must be at least %d characters",
		Spanish: "Debe tener al menos %d caracteres",
	},
	MaxLength: map[Language]string{
		English: "Must be at most %d characters",
		Spanish: "Debe tener como máximo %d caracteres",
	},
	Pattern: map[Language]string{
		English: "Format is not valid",
		Spanish: "El formato no es válido",
	},
	Email: map[Language]string{
		English: "Please enter a valid email address",
		Spanish: "Por favor ingresa una dirección de correo válida",
	},
	URL: map[Language]string{
		English: "Please enter a valid web address",
		Spanish: "Por favor ingresa una dirección web válida",
	},
	UUID: map[Language]string{
		English: "Please enter a valid identifier",
		Spanish: "Por favor ingresa un identificador válido",
	},
	Min: map[Language]string{
		English: "Must be at least %v",
		Spanish: "Debe ser al menos %v",
	},
	Max: map[Language]string{
		English: "Must be at most %v",
		Spanish: "Debe ser como máximo %v",
	},
	Integer: map[Language]string{
		English: "Must be a whole number",
		Spanish: "Debe ser un número entero",
	},
	Positive: map[Language]string{
		English: "Must be a positive number",
		Spanish: "Debe ser un número positivo",
	},
	Negative: map[Language]string{
		English: "Must be a negative number",
		Spanish: "Debe ser un número negativo",
	},
	TypeObject: map[Language]string{
		English: "This field must be an object",
		Spanish: "Este campo debe ser un objeto",
	},
	TypeArray: map[Language]string{
		English: "This field must be a list",
		Spanish: "Este campo debe ser una lista",
	},
	MinItems: map[Language]string{
		English: "Must have at least %d items",
		Spanish: "Debe tener al menos %d elementos",
	},
	MaxItems: map[Language]string{
		English: "Must have at most %d items",
		Spanish: "Debe tener como máximo %d elementos",
	},
}

func getMessage(msgMap map[Language]string, args ...interface{}) string {
	template := msgMap[currentLanguage]
	if template == "" {
		template = msgMap[English] // fallback to English
	}
	
	if len(args) > 0 {
		return fmt.Sprintf(template, args...)
	}
	return template
}