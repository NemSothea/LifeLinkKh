import LanguageSwitcher from '@/components/LanguageSwitcher';
import ThemeSwitcher from '@/components/ThemeSwitcher';

/** The two display preferences every page offers in its header: theme and language. */
export default function SiteControls() {
    return (
        <div className="flex shrink-0 items-center gap-2">
            <ThemeSwitcher />
            <LanguageSwitcher />
        </div>
    );
}
