import 'mocha';
import 'chai';
import { expect } from 'chai';
import { checkCreateTable, checkCreateTableLoc, checkInvalid, checkValid } from './spec-utils';
import { parse, parseFirst } from '../parser';


describe('Edge cases', () => {

    describe('Comment-only / empty input', () => {
        it('returns [] for empty string', () => {
            expect(parse('')).to.deep.equal([]);
        });
        it('returns [] for whitespace only', () => {
            expect(parse('   \n\t  ')).to.deep.equal([]);
        });
        it('returns [] for a line comment only', () => {
            expect(parse('-- just a comment')).to.deep.equal([]);
        });
        it('returns [] for a block comment only', () => {
            expect(parse('/* a block comment */')).to.deep.equal([]);
        });
        it('returns [] for mixed comments and whitespace', () => {
            expect(parse('  -- one\n /* two */ \n')).to.deep.equal([]);
        });
        it('still parses a statement after comments', () => {
            expect(parse('-- lead\nselect 1').length).to.equal(1);
        });
    });


    // https://github.com/oguimbal/pg-mem/issues/171
    describe('Behaviour with table named after keywords', () => {
        const validName = (name: string) => {
            const [schema, qname] = name.split('.');
            checkCreateTable([`create table ${name}(value text)`], {
                type: 'create table',
                name: qname ? { name: qname, schema } : { name },
                columns: [{
                    kind: 'column',
                    name: { name: 'value' },
                    dataType: {
                        name: 'text',
                    },
                }],
            });
        }
        const invalidName = (name: string) => checkInvalid(`create table ${name}(value text)`);

        invalidName('order');
        invalidName('authorization');

        validName('precision');
        validName(`public.order`);
        validName(`public.asc`);


        checkInvalid(`select a precision from (values('a')) as foo(a)`);
        checkValid(`select double val from (values('a')) as foo(double)`)
    });


});