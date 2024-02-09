//! A micro-library for marshaling and unmarshaling global game options.

//# feather use syntax-errors

show_debug_message("enchanted with Witchcraft::validation by @katsaii");

/// A simple pass-through validator which does nothing.
///
/// @param {Any} default_
///   The value to use if validation fails.
///
/// @param {Function} [validator]
///   The validator to use. See `WBasicValidator::__validator__`.
///
/// @param {Function} [decoder]
///   The decoder to use. See `WBasicValidator::__decoder__`.
///
/// @param {Function} [encoder]
///   The encoder to use. See `WBasicValidator::__encoder__`.
function WValidator(
    default_, validator = undefined, decoder = undefined, encoder = undefined
) constructor {
    /// Stores the default value for this validator, used if validation fails
    /// or during the initialisation stage.
    ///
    /// @return {Any}
    self.__default__ = default_;
    /// Stores the validator function.
    ///
    /// @return {Function}
    self.__validator__ = undefined;
    /// Stores the decoder function, responsible for turning an arbitrary
    /// valid value into its canonical representation.
    ///
    /// @return {Function}
    self.__decoder__ = undefined;
    /// Stores the encoder function, responsible for turning the canonical
    /// representation of a value into a form easily readable and writable from
    /// an external file. For example, transforming a colour from an int into
    /// an array of RGB values.
    ///
    /// @return {Function}
    self.__encoder__ = undefined;
    /// @ignore
    ///
    /// @return {Bool}
    self.__isValidator__ = true;

    /// @ignore
    ///
    /// @param {Any} inValue
    ///
    /// @return {Bool}
    static __validateValue = function (inValue) {
        return __validator__ == undefined || __validator__(inValue);
    }

    /// @ignore
    ///
    /// @param {Any} inValue
    ///
    /// @return {Bool}
    static __decodeValue = function (inValue) {
        return __decoder__ == undefined ? inValue : __decoder__(inValue);
    }

    /// @ignore
    ///
    /// @param {Any} inValue
    ///
    /// @return {Bool}
    static __encodeValue = function (inValue) {
        return __encoder__ == undefined ? inValue : __encoder__(inValue);
    }

    /// Decode an input value into its canonical form. If validation fails,
    /// the default value for this validator is returned instead.
    ///
    /// @param {Any} inValue
    ///   The input value to decode.
    ///
    /// @return {Any}
    static decodeValue = function (inValue) {
        if (__validateValue(inValue)) {
            return __decodeValue(inValue);
        }
        // TODO: deep copy if the default is a mutable reference type
        return __default__;
    };

    /// Encode an input value into its serialisable form.
    ///
    /// @param {Any} inValue
    ///   The input value to encode.
    ///
    /// @return {Any}
    static encodeValue = function (inValue) {
        return __encodeValue(inValue);
    };
}

/// Validator for numeric values.
///
/// @param {Any} [default_]
///   The value to use if validation fails. Defaults to 0.
function WNumericValidator(default_ = 0) : WValidator(default_, is_numeric)
        constructor { }

/// Validator for string values.
///
/// @param {Any} [default_]
///   The value to use if validation fails. Defaults to the empty string.
function WStringValidator(default_ = "") : WValidator(default_, , string)
        constructor { }

/// Validator for boolean values.
///
/// @param {Any} [default_]
///   The value to use if validation fails. Defaults to the false.
function WBooleanValidator(default_ = false) : WValidator(default_, is_bool)
        constructor { }

/// Validator for object types.
function WObjectValidator() : WValidator({ }) constructor {
    self.fields = [];
    self.__validator__ = function (json) {
        if (!is_struct(json)) {
            return false;
        }
        for (var i = array_length(fields) - 1; i >= 0; i -= 1) {
            var fieldData = fields[| i];
            var fieldName = fieldData.name;
            if (!variable_struct_exists(json, fieldName)) {
                return false;
            }
            // recursively validate
            if (!fieldData.validator.__validateValue(json[$ fieldName])) {
                return false;
            }
        }
        return true;
    };
    self.__decoder__ = function (json) {
        var validJson = { };
        for (var i = array_length(fields) - 1; i >= 0; i -= 1) {
            var fieldData = fields[| i];
            var fieldName = fieldData.name;
            validJson[$ fieldName] =
                    fieldData.validator.__decodeValue(json[$ fieldName]);
        }
        return validJson;
    };
    self.__encoder__ = function (json) {
        var validJson = { };
        for (var i = array_length(fields) - 1; i >= 0; i -= 1) {
            var fieldData = fields[| i];
            var fieldName = fieldData.name;
            validJson[$ fieldName] =
                    fieldData.validator.__encodeValue(json[$ fieldName]);
        }
        return validJson;
    };

    /// Registers a new field to this object validator.
    ///
    /// @param {String} name
    ///   The name of this object field.
    ///
    /// @param {Struct.WValidator} validator
    ///   The validator for this object field.
    static addField = function (name, validator) {
        array_push(fields, { name : name, validator : validator });
        __default__[$ name] = validator.__default__;
    };
}

/// Validator for array types.
function WArrayValidator() : WValidator([]) constructor {
    self.fields = [];
    self.__validator__ = function (json) {
        if (!is_array(json)) {
            return false;
        }
        var expectedLength = array_length(fields);
        if (expectedLength != array_length(json)) {
            return false;
        }
        for (var i = expectedLength - 1; i >= 0; i -= 1) {
            var fieldValidator = fields[| i];
            // recursively validate
            if (!fieldValidator.__validateValue(json[i])) {
                return false;
            }
        }
        return true;
    };
    self.__decoder__ = function (json) {
        var validJson = [];
        for (var i = array_length(fields) - 1; i >= 0; i -= 1) {
            var fieldValidator = fields[| i];
            validJson[@ i] = fieldValidator.__decodeValue(json[i]);
        }
        return validJson;
    };
    self.__encoder__ = function (json) {
        var validJson = [];
        for (var i = array_length(fields) - 1; i >= 0; i -= 1) {
             var fieldValidator = fields[| i];
            validJson[@ i] = fieldValidator.__encodeValue(json[i]);
        }
        return validJson;
    };

    /// Registers a new field to this array validator.
    ///
    /// @param {Struct.WValidator} validator
    ///   The validator for this array element.
    static addField = function (validator) {
        array_push(fields, validator);
        array_push(__default__, validator.__default__);
    };
}

/// Create a new validator from a compact schema, where the validation method
/// is inferred in most cases.
///
/// @param {Struct} schema
///   The schema to build the validator from.
function wvalidator_from_schema(schema) {
    if (is_bool(schema)) {
        return new WBooleanValidator(schema);
    } else if (is_string(schema)) {
        return new WStringValidator(schema);
    } else if (is_numeric(schema)) {
        return new WNumericValidator(schema);
    } else if (is_array(schema)) {
        var validator = new WArrayValidator();
        var n = array_length(schema);
        for (var i = 0; i < n; i += 1) {
            validator.addField(wvalidator_from_schema(schema[i]));
        }
        return validator;
    } else if (is_struct(schema)) {
        if (variable_struct_exists(schema, "__isValidator__")) {
            // good enough to decide whether this is a validator struct
            return schema;
        }
        var validator = new WObjectValidator();
        var varNames = variable_struct_get_names(schema);
        for (var i = array_length(varNames) - 1; i >= 0; i -= 1) {
            var varName = varNames[i];
            var varSchema = schema[$ varName];
            validator.addField(varName, wvalidator_from_schema(varSchema));
        }
        return validator;
    }
    // passthrough
    return new WValidator(schema);
}