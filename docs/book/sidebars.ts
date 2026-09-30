import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

// One sidebar, in reading order: people who use the app first, people who build it after.
// Labels are Khmer (the default locale); English lives in i18n/en/docusaurus-plugin-content-docs/current.json.
const sidebars: SidebarsConfig = {
    book: [
        'intro',
        {
            type: 'category',
            label: 'ការប្រើកម្មវិធី',
            collapsed: false,
            items: ['install', 'donor-guide', 'requester-guide', 'faq'],
        },
        {
            type: 'category',
            label: 'ការអភិវឌ្ឍ LifeLink',
            collapsed: false,
            items: ['architecture', 'contributing', 'decisions'],
        },
        'glossary',
    ],
};

export default sidebars;
