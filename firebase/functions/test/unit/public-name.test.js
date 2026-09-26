import { describe, expect, test } from 'vitest';
import { publicName } from '../../src/on-match-answered.js';

describe('publicName — what the signed-out board shows', () => {
  test('the first word, then initials', () => {
    expect(publicName('Nem Sothea')).toBe('Nem S.');
    expect(publicName('Sok Dara Vann')).toBe('Sok D. V.');
  });

  test('Khmer script is shortened the same way', () => {
    expect(publicName('នឹម សុធា')).toBe('នឹម ស.');
  });

  test('one word stays one word; extra spaces and empty names do not break it', () => {
    expect(publicName('Sothea')).toBe('Sothea');
    expect(publicName('  Nem   Sothea  ')).toBe('Nem S.');
    expect(publicName('')).toBe('');
    expect(publicName(undefined)).toBe('');
  });
});
