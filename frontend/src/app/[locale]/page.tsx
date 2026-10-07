import { getTranslations } from 'next-intl/server';
import Image from 'next/image';
import Link from 'next/link';
import {
    ArrowRight,
    Building2,
    Check,
    CodeXml,
    Download,
    Droplet,
    FileText,
    Heart,
    Mail,
    Phone,
    Search,
    ShieldCheck,
    UserRound,
    Users,
} from 'lucide-react';
import PublicHeader from '@/components/PublicHeader';
import { SUPPORT_PHONE } from '@/lib/support';
import styles from './landing.module.css';

const SOURCE_URL = 'https://github.com/NemSothea/LifeLinkKh';
type Step = { title: string; body: string };
type TeamMember = { name: string; role: string };

export default async function HomePage({ params }: { params: Promise<{ locale: string }> }) {
    const { locale } = await params;
    const home = await getTranslations('home');
    const t = await getTranslations('landing');
    const steps = t.raw('steps') as Step[];
    const safety = home.raw('safety') as string[];
    const team = home.raw('team') as TeamMember[];
    const supportEmail = process.env.SUPPORT_EMAIL?.trim() || null;
    const stepIcons = [FileText, Search, UserRound];
    const safetyIcons = [Heart, ShieldCheck, Building2, Download, ShieldCheck];
    const download = `/${locale}/download`;
    const guide = `/${locale}/getting-blood`;
    const portal = `/${locale}/portal`;

    return (
        <div className={styles.page}>
            <div className={styles.container}>
                <PublicHeader locale={locale} home />

                <main id="main-content">
                    <section className={styles.hero} aria-labelledby="hero-heading">
                        <div className={styles.heroCopy}>
                            <p className={styles.eyebrow}>{t('eyebrow')}</p>
                            <h1 id="hero-heading" className={styles.headline}>
                                {t('headline')} <span>{t('headlineAccent')}</span>
                            </h1>
                            <p className={styles.intro}>{t('intro')}</p>
                            <div className={styles.actions}>
                                <Link
                                    href={download}
                                    data-testid="home-download-link"
                                    className={`${styles.button} ${styles.primary}`}
                                >
                                    <Download size={21} aria-hidden="true" />
                                    {t('download')}
                                </Link>
                                <Link
                                    href={guide}
                                    data-testid="home-guide-link"
                                    className={`${styles.button} ${styles.secondary}`}
                                >
                                    <Users size={21} aria-hidden="true" />
                                    {t('guide')}
                                </Link>
                            </div>
                            <p className={styles.installNote}>{t('installNote')}</p>
                            <ul className={styles.reassurance}>
                                {[
                                    { Icon: ShieldCheck, text: t('reviewed') },
                                    { Icon: Heart, text: t('free') },
                                    { Icon: Users, text: t('contactPrivacy') },
                                ].map(({ Icon, text }) => (
                                    <li key={text}>
                                        <span>
                                            <Icon size={20} aria-hidden="true" />
                                        </span>
                                        {text}
                                    </li>
                                ))}
                            </ul>
                        </div>
                        <figure className={styles.appFigure}>
                            <div className={styles.phonePanel}>
                                <span className={styles.heroMotif} aria-hidden="true">
                                    <Droplet />
                                </span>
                                <div className={styles.phone}>
                                    <Image
                                        src={`/landing/app-home-${locale === 'km' ? 'km' : 'en'}.png`}
                                        alt={t('appAlt')}
                                        width={720}
                                        height={1760}
                                        sizes="(max-width: 700px) 160px, 236px"
                                        preload
                                    />
                                </div>
                            </div>
                            <figcaption>{t('appCaption')}</figcaption>
                        </figure>
                    </section>

                    <section className={styles.pathways} aria-label={t('pathways')}>
                        {[
                            {
                                href: download,
                                Icon: Droplet,
                                title: t('donorTitle'),
                                body: t('donorBody'),
                                action: t('donorAction'),
                                art: 'donor',
                            },
                            {
                                href: guide,
                                Icon: Users,
                                title: t('familyTitle'),
                                body: t('familyBody'),
                                action: t('familyAction'),
                                art: 'family',
                            },
                        ].map(({ href, Icon, title, body, action, art }) => (
                            <Link href={href} key={art} className={styles.pathCard}>
                                <span className={styles.pathIcon}>
                                    <Icon size={27} aria-hidden="true" />
                                </span>
                                <div>
                                    <h2>{title}</h2>
                                    <p>{body}</p>
                                    <span className={styles.textLink}>
                                        {action}
                                        <ArrowRight size={17} aria-hidden="true" />
                                    </span>
                                </div>
                                <Image
                                    src={`/landing/${art}.svg`}
                                    width={130}
                                    height={98}
                                    alt=""
                                    className={styles.pathArt}
                                />
                            </Link>
                        ))}
                    </section>

                    <section
                        id="how-it-works"
                        className={styles.section}
                        data-testid="home-how"
                        aria-labelledby="how-heading"
                    >
                        <h2 id="how-heading" className={styles.sectionHeading}>
                            {t('howHeading')}
                        </h2>
                        <ol className={styles.steps}>
                            {steps.map((step, i) => {
                                const Icon = stepIcons[i];
                                return (
                                    <li key={step.title}>
                                        <div className={styles.stepSymbol}>
                                            <span>{String(i + 1).padStart(2, '0')}</span>
                                            <Icon size={29} aria-hidden="true" />
                                        </div>
                                        <div>
                                            <h3>{step.title}</h3>
                                            <p>{step.body}</p>
                                        </div>
                                        {i < steps.length - 1 && (
                                            <ArrowRight
                                                className={styles.connector}
                                                aria-hidden="true"
                                            />
                                        )}
                                    </li>
                                );
                            })}
                        </ol>
                    </section>

                    <section
                        id="open-requests"
                        className={styles.board}
                        aria-labelledby="board-heading"
                    >
                        <div>
                            <h2 id="board-heading" className={styles.sectionHeading}>
                                {t('boardHeading')}
                            </h2>
                            <p>{t('boardBody')}</p>
                            <Link
                                href={portal}
                                data-testid="home-portal-link"
                                className={`${styles.button} ${styles.outline}`}
                            >
                                {t('boardAction')}
                                <ArrowRight size={18} aria-hidden="true" />
                            </Link>
                        </div>
                        <div className={styles.boardInvitation}>
                            <div className={styles.bloodTypes} aria-hidden="true">
                                {['O+', 'A+', 'B+', 'AB+'].map((type) => (
                                    <span key={type}>{type}</span>
                                ))}
                            </div>
                            <h3>{t('boardInvitation')}</h3>
                            <p>{t('boardDetail')}</p>
                            <span className={styles.boardAccess}>
                                <Check size={16} aria-hidden="true" />
                                {t('boardAccess')}
                            </span>
                        </div>
                    </section>

                    <div className={styles.trustGrid}>
                        <section data-testid="home-safety" aria-labelledby="safety-heading">
                            <h2 id="safety-heading" className={styles.sectionHeading}>
                                {t('safetyHeading')}
                            </h2>
                            <ul className={styles.safety}>
                                {safety.map((item, i) => {
                                    const Icon = safetyIcons[i];
                                    return (
                                        <li key={item}>
                                            <span>
                                                <Icon size={22} aria-hidden="true" />
                                            </span>
                                            <p>{item}</p>
                                        </li>
                                    );
                                })}
                            </ul>
                        </section>
                        <section
                            id="about"
                            data-testid="home-about"
                            className={styles.about}
                            aria-labelledby="about-heading"
                        >
                            <Image
                                src="/landing/angkor-wat.png"
                                width={2008}
                                height={783}
                                sizes="(max-width: 700px) 90vw, 480px"
                                alt=""
                                className={styles.temple}
                            />
                            <div className={styles.provenance}>
                                <h2 id="about-heading" className={styles.sectionHeading}>
                                    {t('madeIn')}
                                </h2>
                                <p>{t('aboutSummary')}</p>
                            </div>
                            <details className={styles.teamDetails}>
                                <summary>
                                    {t('teamSource')}
                                    <ArrowRight size={17} aria-hidden="true" />
                                </summary>
                                <p className={styles.fullAbout}>{home('aboutBody')}</p>
                                <h3 className={styles.teamLabel}>{home('teamLabel')}</h3>
                                <ol data-testid="home-team" className={styles.team}>
                                    {team.map((member, i) => (
                                        <li key={member.name}>
                                            <span>{String(i + 1).padStart(2, '0')}</span>
                                            <div>
                                                <strong>{member.name}</strong>
                                                <p>{member.role}</p>
                                            </div>
                                        </li>
                                    ))}
                                </ol>
                                <p data-testid="home-lecturer" className={styles.lecturer}>
                                    <strong>{home('lecturerLabel')}</strong> {home('lecturer')}
                                </p>
                                <a
                                    href={SOURCE_URL}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className={styles.textLink}
                                >
                                    <CodeXml size={18} aria-hidden="true" />
                                    {home('sourceLink')}
                                    <ArrowRight size={17} aria-hidden="true" />
                                </a>
                            </details>
                            <div className={styles.contact} data-testid="home-contact">
                                <p>{t('contactSummary')}</p>
                                <details className={styles.contactDetails}>
                                    <summary>
                                        <Mail size={17} aria-hidden="true" />
                                        {t('contactTeam')}
                                    </summary>
                                    <p>{home('contactBody')}</p>
                                    <div className={styles.contactLinks}>
                                        <a
                                            href={`tel:${SUPPORT_PHONE.tel}`}
                                            data-testid="home-contact-phone"
                                            className={`${styles.button} ${styles.secondary}`}
                                        >
                                            <Phone size={17} aria-hidden="true" />
                                            {SUPPORT_PHONE.carrier}: {SUPPORT_PHONE.display}
                                        </a>
                                        {supportEmail && (
                                            <a
                                                href={`mailto:${supportEmail}`}
                                                className={`${styles.button} ${styles.secondary}`}
                                            >
                                                <Mail size={17} aria-hidden="true" />
                                                {supportEmail}
                                            </a>
                                        )}
                                    </div>
                                </details>
                            </div>
                        </section>
                    </div>
                    <section className={styles.finalCta} aria-label={t('download')}>
                        <div>
                            <h2>{t('finalHeading')}</h2>
                            <p>{t('installNote')}</p>
                        </div>
                        <Link href={download} className={`${styles.button} ${styles.primary}`}>
                            <Download size={20} aria-hidden="true" />
                            {t('download')}
                        </Link>
                    </section>
                </main>
            </div>
        </div>
    );
}
