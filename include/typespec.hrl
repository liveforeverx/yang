-record(field, {name, description, type, 'when', default, mandatory = false, opts}).
-record(typedef, {name, description, type, default, opts}).
-record(struct, {fields, opts}).
-record(object, {name, description, fields, 'when', opts}).
-record(array, {name, description, type, 'when', mandatory = false, opts}).
-record(rpc, {name, description, input, output, fields, opts}).
-record(choice, {name, description, cases, 'when', default, mandatory = false, opts}).
-record('case', {name, description, fields, 'when', opts}).

-record(enumeration, {enum}).
-record(string, {length, pattern}).
-record(binary, {length}).
