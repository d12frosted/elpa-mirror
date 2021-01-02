
Variables can be defined as:

@db   = `test`
@id   =  1234
@name = "John Doe"

and the query can be:

SELECT * FROM @db.users WHERE id = @id OR name = @name;

NOTE: The parameters are not escaped as the values are define by the user and
hence it is a trusted source. However, functionality for evaluating a value
will probably be added in the future which would require the values to be
escaped (hence, a breaking change is expected in the future).
