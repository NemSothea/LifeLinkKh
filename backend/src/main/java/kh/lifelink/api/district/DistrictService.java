package kh.lifelink.api.district;

import java.text.Collator;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import kh.lifelink.api.district.dto.DistrictResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Reference data behind the donor-registration dropdown (CR-MAPI-002).
 *
 * <p>Thin, and deliberately so — there is no rule to enforce over a list of 14 khans. It exists
 * because {@code DistrictController} reaching for {@code DistrictRepository} made this the one area
 * that skipped the layer every other area goes through, and an inconsistency is answered at the
 * defence whether or not it was reasonable. The sort below is the argument for it being a service
 * at all: it is a decision about what the data means, not about how to serve it.
 */
@Service
public class DistrictService {

    private final DistrictRepository districts;

    DistrictService(DistrictRepository districts) {
        this.districts = districts;
    }

    /**
     * Sorted by Khmer name, which is a PO rule and not a detail: code order is administrative
     * history and means nothing to a donor scanning for their own khan.
     *
     * <p>Sorted here rather than in the client so both clients agree, and rather than in SQL
     * because Postgres' Khmer collation depends on the container's locale — a sort that changes
     * with the base image is worse than one that is slightly wrong. A {@code Collator} rather than
     * natural {@code String} order for the same reason it matters at all: UTF-16 order puts
     * subscript consonants and dependent vowels wherever their code points happen to fall, which is
     * not where a reader looks.
     */
    @Transactional(readOnly = true)
    public List<DistrictResponse> list() {
        Collator khmer = Collator.getInstance(Locale.forLanguageTag("km"));
        return districts.findAll().stream()
                .map(d -> new DistrictResponse(d.getCode(), d.getNameKm(), d.getNameEn()))
                .sorted(Comparator.comparing(DistrictResponse::nameKm, khmer))
                .toList();
    }
}
