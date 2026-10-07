import 'mocha';
import 'chai';
import { checkInvalid, checkStatement, columns, tbl } from './spec-utils';

describe('Create view statements', () => {

    checkStatement(`create view myview as select * from tbl`, {
        type: 'create view',
        name: { name: 'myview' },
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
    });


    checkStatement(`create or replace view myview (a,b) as select * from tbl`, {
        type: 'create view',
        name: { name: 'myview' },
        columnNames: [{ name: 'a' }, { name: 'b' }],
        orReplace: true,
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
    });



    checkStatement(`create view myview (a) as select * from tbl`, {
        type: 'create view',
        name: { name: 'myview' },
        columnNames: [{ name: 'a' }],
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
    });


    checkStatement(`create recursive view myview as select * from tbl`, {
        type: 'create view',
        name: { name: 'myview' },
        recursive: true,
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
    });


    checkStatement(`create view myview as select * from tbl with local check option`, {
        type: 'create view',
        name: { name: 'myview' },
        checkOption: 'local',
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
    });

    checkStatement(`create view myview as select * from tbl with cascaded check option`, {
        type: 'create view',
        name: { name: 'myview' },
        checkOption: 'cascaded',
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
    });

    checkStatement([`create temp view myview as select * from tbl`, `CREATE TEMPORARY VIEW myview AS select * from tbl`], {
        type: 'create view',
        name: { name: 'myview' },
        temp: true,
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
    });



    checkStatement([`create materialized view myview as select * from tbl`], {
        type: 'create materialized view',
        name: { name: 'myview' },
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
    });



    checkStatement([`create view myview with pa = va as select * from tbl`], {
        type: 'create view',
        name: { name: 'myview' },
        parameters: { pa: 'va' },
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
    });

    checkStatement([`create view public.myview as select * from tbl`], {
        type: 'create view',
        name: { name: 'myview', schema: 'public', },
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
    });

    checkStatement([`create materialized view myview with pa = va as select * from tbl`], {
        type: 'create materialized view',
        name: { name: 'myview' },
        parameters: { pa: 'va' },
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
    });

    checkStatement([`create materialized view myview with pa = va, pb = vb as select * from tbl`], {
        type: 'create materialized view',
        name: { name: 'myview' },
        parameters: { pa: 'va', pb: 'vb' },
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
    });



    checkStatement([`create materialized view myview as select * from tbl with data`], {
        type: 'create materialized view',
        name: { name: 'myview' },
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
        withData: true,
    });


    checkStatement([`create materialized view myview as select * from tbl with no data`], {
        type: 'create materialized view',
        name: { name: 'myview' },
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
        withData: false,
    });


    checkStatement([`create materialized view public.myview as select * from tbl`], {
        type: 'create materialized view',
        name: {
            name: 'myview',
            schema: 'public',
        },
        query: {
            type: 'select',
            columns: columns('*'),
            from: [tbl('tbl')],
        },
    });

    checkInvalid(`create view myview as select * from tbl with data`);
    checkInvalid(`create or replace materialized view myview as select * from tbl with data`);
    checkStatement([`create view v with (security_invoker = true, security_barrier) as select 1`], {
        type: 'create view',
        name: { name: 'v' },
        parameters: { security_invoker: 'true', security_barrier: 'true' },
        query: {
            type: 'select',
            columns: [{ expr: { type: 'integer', value: 1 } }],
        },
    });
    checkStatement([`create view v with (security_invoker = on) as select 1`, `create view v with (security_invoker=on) as select 1`], {
        type: 'create view',
        name: { name: 'v' },
        parameters: { security_invoker: 'on' },
        query: {
            type: 'select',
            columns: [{ expr: { type: 'integer', value: 1 } }],
        },
    });
    checkStatement([`create view v with (security_invoker = off) as select 1`], {
        type: 'create view',
        name: { name: 'v' },
        parameters: { security_invoker: 'off' },
        query: {
            type: 'select',
            columns: [{ expr: { type: 'integer', value: 1 } }],
        },
    });
    checkStatement([`create materialized view mv with (fillfactor = 70) as select 1`], {
        type: 'create materialized view',
        name: { name: 'mv' },
        parameters: { fillfactor: '70' },
        query: {
            type: 'select',
            columns: [{ expr: { type: 'integer', value: 1 } }],
        },
    });
});
