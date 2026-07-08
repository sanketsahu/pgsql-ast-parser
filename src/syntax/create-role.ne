@lexer lexerAny
@include "base.ne"

# https://www.postgresql.org/docs/current/sql-createrole.html
# CREATE USER is CREATE ROLE with LOGIN implied.
createrole_statement -> %kw_create (kw_role | %kw_user) ident %kw_with:? role_option:* {% x => track(x, {
    type: 'create role',
    name: asName(x[2]),
    // "user" (the keyword token) implies LOGIN
    ...(toStr(unwrap(x[1])).toLowerCase() === 'user' ? { options: mergeRoleOptions([{ login: true }, ...(x[4] || [])]) } : { options: mergeRoleOptions(x[4] || []) }),
}) %}

@{%
function mergeRoleOptions(opts: any[]) {
    return Object.assign({}, ...opts);
}
%}

role_option
    -> kw_superuser {% () => ({ superuser: true }) %}
    | kw_nosuperuser {% () => ({ superuser: false }) %}
    | kw_login {% () => ({ login: true }) %}
    | kw_nologin {% () => ({ login: false }) %}
    | kw_bypassrls {% () => ({ bypassRls: true }) %}
    | kw_nobypassrls {% () => ({ bypassRls: false }) %}
    # parsed but not modelled (kept lenient for dumps):
    | (kw_password string) {% () => ({}) %}
    | kw_createdb {% () => ({}) %}
    | kw_nocreatedb {% () => ({}) %}
    | kw_createrole {% () => ({}) %}
    | kw_nocreaterole {% () => ({}) %}
    | kw_inherit {% () => ({}) %}
    | kw_noinherit {% () => ({}) %}
