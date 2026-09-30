import type * as Preset from '@docusaurus/preset-classic';
import type { Config } from '@docusaurus/types';
import { themes as prismThemes } from 'prism-react-renderer';

// The handbook: Khmer first, English one click away. Published to GitHub Pages by
// .github/workflows/book.yml. Links into the repo point at the default branch.
const REPO = 'https://github.com/NemSothea/LifeLinkKh';
const BRANCH = 'feat/firebase-backend';
const PORTAL = 'https://lifelinkkh.vercel.app';

// Labels below are Khmer (the default locale). English: i18n/en/docusaurus-theme-classic/*.json.
const config: Config = {
    title: 'LifeLink KH · ជីវិត',
    tagline: 'សៀវភៅណែនាំ LifeLink KH · The LifeLink KH handbook',
    favicon: 'img/icon.png',
    url: 'https://nemsothea.github.io',
    baseUrl: '/LifeLinkKh/',
    organizationName: 'NemSothea',
    projectName: 'LifeLinkKh',
    trailingSlash: false,
    onBrokenLinks: 'throw',
    markdown: { hooks: { onBrokenMarkdownLinks: 'throw' } },

    i18n: {
        defaultLocale: 'km',
        locales: ['km', 'en'],
        localeConfigs: {
            km: { label: 'ខ្មែរ', htmlLang: 'km' },
            en: { label: 'English', htmlLang: 'en' },
        },
    },

    headTags: [
        { tagName: 'link', attributes: { rel: 'preconnect', href: 'https://fonts.googleapis.com' } },
        {
            tagName: 'link',
            attributes: { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: 'anonymous' },
        },
        {
            tagName: 'link',
            attributes: {
                rel: 'stylesheet',
                href: 'https://fonts.googleapis.com/css2?family=Inter:wght@400..700&family=Kantumruy+Pro:wght@400..700&display=swap',
            },
        },
    ],

    presets: [
        [
            'classic',
            {
                docs: {
                    routeBasePath: '/',
                    sidebarPath: './sidebars.ts',
                    editUrl: ({ locale, docPath }) =>
                        locale === 'km'
                            ? `${REPO}/edit/${BRANCH}/docs/book/docs/${docPath}`
                            : `${REPO}/edit/${BRANCH}/docs/book/i18n/${locale}/docusaurus-plugin-content-docs/current/${docPath}`,
                    showLastUpdateTime: false,
                },
                blog: false,
                theme: { customCss: './src/css/custom.css' },
                sitemap: { changefreq: 'monthly', priority: 0.5 },
            } satisfies Preset.Options,
        ],
    ],

    themeConfig: {
        image: 'img/social-card.png',
        metadata: [
            {
                name: 'description',
                content:
                    'LifeLink KH handbook: how to donate and request blood with the app, and how to contribute. Khmer and English.',
            },
        ],
        colorMode: { respectPrefersColorScheme: true },
        navbar: {
            title: 'LifeLink KH',
            logo: { alt: 'LifeLink KH', src: 'img/icon.png' },
            items: [
                { type: 'docSidebar', sidebarId: 'book', position: 'left', label: 'សៀវភៅណែនាំ' },
                { href: PORTAL, label: 'គេហទំព័រ', position: 'right' },
                { href: REPO, label: 'GitHub', position: 'right' },
                { type: 'localeDropdown', position: 'right' },
            ],
        },
        footer: {
            style: 'dark',
            links: [
                {
                    title: 'LifeLink KH',
                    items: [
                        { label: 'គេហទំព័រ', href: `${PORTAL}/km` },
                        { label: 'ទាញយកកម្មវិធី', href: `${PORTAL}/km/download` },
                        { label: 'របៀបរកឈាមសម្រាប់អ្នកជំងឺ', href: `${PORTAL}/km/getting-blood` },
                    ],
                },
                {
                    title: 'សហគមន៍',
                    items: [
                        { label: 'GitHub', href: REPO },
                        { label: 'Discussions', href: `${REPO}/discussions` },
                        { label: 'កិច្ចការសម្រាប់អ្នកថ្មី', href: `${REPO}/labels/good%20first%20issue` },
                    ],
                },
            ],
            copyright:
                'LifeLink KH ជួយភ្ជាប់អ្នកបរិច្ចាគឈាម និងអ្នកជំងឺ។ វាមិនជំនួសមជ្ឈមណ្ឌលជាតិផ្តល់ឈាម ឬដំបូន្មានវេជ្ជសាស្ត្រឡើយ។ · ' +
                'អត្ថបទ CC BY 4.0 · កូដ Apache-2.0 — LifeLink KH contributors',
        },
        prism: { theme: prismThemes.github, darkTheme: prismThemes.dracula },
    } satisfies Preset.ThemeConfig,
};

export default config;
