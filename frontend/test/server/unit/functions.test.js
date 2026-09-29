import { describe, expect, test } from 'vitest';
import { FUNCTION_NAMES, FUNCTIONS, functionNamed } from '../../../src/server/functions.js';

describe('functionNamed — which wire names run a handler', () => {
    test('every listed function is found', () => {
        for (const name of FUNCTION_NAMES) expect(functionNamed(name)).toBe(FUNCTIONS[name]);
    });

    // SEC-REVIEW-003 F-01: names every object inherits must not reach a handler call.
    test.each([
        'constructor',
        'toString',
        'hasOwnProperty',
        'valueOf',
        '__proto__',
        'isPrototypeOf',
    ])('%s is not a function', (name) => {
        expect(functionNamed(name)).toBeUndefined();
    });

    test('unknown and empty names are not functions', () => {
        expect(functionNamed('nope')).toBeUndefined();
        expect(functionNamed('')).toBeUndefined();
    });
});
