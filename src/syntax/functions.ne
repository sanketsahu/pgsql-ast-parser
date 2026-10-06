@lexer lexerAny
@include "base.ne"

functions_statements -> create_func | do_stm | drop_func

array_of[EXP] -> $EXP (%comma $EXP {% last %}):* {% ([head, tail]) => {
    return [unwrap(head), ...(tail.map(unwrap) || [])];
} %}

# https://www.postgresql.org/docs/13/sql-createfunction.html
create_func -> %kw_create
                (%kw_or kw_replace):?
                kw_function
                qname
                (lparen array_of[func_argdef]:? rparen {% get(1) %})
                func_spec:+ {% (x, rej) => {
                    const specs: any = {};
                    for (const s of x[5]) {
                        if (s.settings) {
                            // SET clauses may repeat (one per parameter)
                            specs.settings = [...(specs.settings ?? []), ...s.settings];
                            continue;
                        }
                        for (const k in s) {
                            if (k[0] !== '_' && k in specs) {
                                throw new Error('conflicting or redundant options ' + k);
                            }
                        }
                        Object.assign(specs, s);
                    }

                    return track(x, {
                        type: 'create function',
                        ...x[1] && {orReplace: true},
                        name: x[3],
                        arguments: x[4] ?? [],
                        ...specs,
                    });
                } %}


func_argdef -> func_argopts:?
                    data_type
                    func_argdefault:?
                    {% x => track(x, {
                        default: x[2],
                        type: x[1],
                        ...x[0],
                    }) %}

func_argdefault -> %kw_default expr {%
                     x => x[1]
                   %}
                   | %op_eq expr {% x => x[1] %}

func_argopts -> func_argmod word:? {% x => track(x, {
                        mode: toStr(x[0]),
                        ...x[1] && { name: asName(x[1]) },
                    }) %}
                | word {% (x, rej) => {
                    const name = asName(x);
                    if (name === 'out' || name === 'inout' || name === 'variadic') {
                        return rej; // avoid ambiguous syntax
                    }
                    return track(x, {name});
                } %}

func_argmod -> %kw_in | kw_out | kw_inout | kw_variadic

func_spec -> kw_language word {% x => track(x, { language: asName(last(x)) }) %}
         | func_purity {% x => track(x, {purity: toStr(x)}) %}
         | %kw_as (%codeblock | string) {% x =>({code: toStr(last(x))}) %}
         | %kw_not:? (word {% kw('leakproof') %}) {% x => track(x, { leakproof: !x[0] })%}
         | func_returns {% x => {
                const r = unwrap(x);
                return r && r.__setof
                    ? track(x, { returns: r.__setof, setof: true })
                    : track(x, { returns: r });
            } %}
         | (word {%kw('called')%}) oninp {% () => ({ onNullInput: 'call' }) %}
         | (word {%kw('returns')%}) %kw_null oninp {% () => ({ onNullInput: 'null' }) %}
         | (word {%kw('strict')%})  {% () => ({ onNullInput: 'strict' }) %}
         | (word {%kw('external')%}):? (word {%kw('security')%}) (word {%kw('definer')%} | word {%kw('invoker')%}) {% x => track(x, { security: toStr(last(x)) }) %}
         # SET search_path = public, extensions | SET search_path TO '' | SET x FROM CURRENT
         | kw_set ident (%op_eq | %kw_to) func_set_values {% x => track(x, { settings: [{ name: asName(x[1]), value: x[3] }] }) %}
         | kw_set ident %kw_from kw_current {% x => track(x, { settings: [{ name: asName(x[1]), fromCurrent: true }] }) %}
         | (word {%kw('cost')%}) %float {% x => track(x, { cost: Number(toStr(last(x))) }) %}
         | (word {%kw('cost')%}) int {% x => track(x, { cost: unwrap(last(x)) }) %}
         | kw_rows int {% x => track(x, { rows: unwrap(last(x)) }) %}
         | (word {%kw('parallel')%}) (word {%kw('safe')%} | word {%kw('unsafe')%} | word {%kw('restricted')%}) {% x => track(x, { parallel: toStr(last(x)) }) %}

func_set_values -> %kw_default {% () => 'default' %}
                | array_of[func_set_value] {% id %}

func_set_value -> ident {% x => toStr(x) %}
                | string {% x => toStr(x) %}
                | int {% x => String(unwrap(x)) %}
                | %kw_true {% () => 'true' %}
                | %kw_false {% () => 'false' %}

func_purity -> word {%kw('immutable')%}
            |  word {%kw('stable')%}
            |  word {%kw('volatile')%}

oninp -> %kw_on %kw_null (word {%kw('input')%})

func_returns -> kw_returns data_type {% last %}
                | kw_returns kw_setof data_type {% x => ({ __setof: last(x) }) %}
                | kw_returns %kw_table lparen array_of[func_ret_table_col] rparen {% x => track(x, {
                    kind: 'table',
                    columns: x[3],
                }) %}

func_ret_table_col -> word data_type {% x => track(x, {name: asName(x[0]), type: x[1]}) %}

# https://www.postgresql.org/docs/13/sql-do.html
do_stm -> %kw_do (kw_language word {% last %}):? %codeblock {% x => track(x, {
    type: 'do',
    ...x[1] && { language: asName(x[1])},
    code: x[2].value,
}) %}



drop_func -> kw_drop
     kw_function
    (kw_if kw_exists):?
    qname
    drop_func_overload:?
    (kw_cascade | kw_restrict):? {% x => track(x, {
        type: 'drop function',
        ...x[2] && {ifExists: true},
        name: x[3],
        ...x[4] && {arguments: x[4]},
        ...x[5] && {cascade: toStr(x[5])},
    }) %}


# f() names the zero-argument overload
drop_func_overload -> lparen array_of[drop_func_overload_col]:? rparen {% x => x[1] ?? [] %}

drop_func_overload_col -> word:? qname {% x => track(x, {
    type: x[1],
    ... x[0] && {name: asName(x[0])},
}) %}
