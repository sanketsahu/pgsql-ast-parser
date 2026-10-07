@lexer lexerAny
@include "base.ne"
@include "expr.ne"

# https://www.postgresql.org/docs/current/sql-createtrigger.html
# CREATE OR REPLACE TRIGGER is postgres 14+
createtrigger_statement -> %kw_create (%kw_or kw_replace {% () => true %}):? (%kw_constraint {% () => true %}):? kw_trigger ident
            trigger_timing
            trigger_events
            %kw_on qualified_name
            (%kw_for kw_each:? (kw_row | kw_statement) {% x => toStr(last(x)).toLowerCase() %}):?
            (%kw_when lparen expr rparen {% x => x[2] %}):?
            kw_execute (kw_function | kw_procedure) qualified_name lparen expr_list_raw:? rparen
            {% x => track(x, {
                type: 'create trigger',
                ...(x[1] ? { orReplace: true } : {}),
                ...(x[2] ? { constraint: true } : {}),
                name: asName(x[4]),
                timing: x[5],
                events: x[6],
                table: x[8],
                forEach: x[9] ?? 'statement',
                ...(x[10] ? { when: unwrap(x[10]) } : {}),
                execute: {
                    function: x[13],
                    arguments: x[15] ?? [],
                },
            }) %}

trigger_timing
    -> kw_before {% () => 'before' %}
    | kw_after {% () => 'after' %}
    | kw_instead kw_of {% () => 'instead of' %}

trigger_events -> trigger_event (%kw_or trigger_event {% last %}):* {% ([head, tail]) => [head, ...(tail || [])] %}

trigger_event
    -> kw_insert {% x => track(x, { event: 'insert' }) %}
    | kw_delete {% x => track(x, { event: 'delete' }) %}
    | kw_truncate {% x => track(x, { event: 'truncate' }) %}
    | kw_update (kw_of collist {% last %}):? {% x => track(x, {
        event: 'update',
        ...(x[1] ? { columns: x[1].map(asName) } : {}),
    }) %}
