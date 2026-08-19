package kh.lifelink.api.district;

import java.text.Collator;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import kh.lifelink.api.district.dto.DistrictResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The district list behind the donor-registration dropdown (CR-MAPI-002).
 *
 * <p>Reference data, and the client cannot hold its own copy: {@code district_code} is a foreign
 * key, so a stale bundled list produces a 422 on save that the donor cannot act on. Reading it from
 * the server is what keeps the dropdown and the constraint in step.
 *
 * <p>Authenticated like everything else. Nothing here is secret — 14 public place names — but the
 * deny-by-default chain has exactly three exemptions and this is not one of them; adding a fourth
 * to save one round trip would trade a security property for nothing.
 */
@RestController
@RequestMapping("/districts")
public class DistrictController {

    private final DistrictRepository districts;

    DistrictController(DistrictRepository districts) {
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
    @GetMapping
    List<DistrictResponse> list() {
        Collator khmer = Collator.getInstance(Locale.forLanguageTag("km"));
        return districts.findAll().stream()
                .map(d -> new DistrictResponse(d.getCode(), d.getNameKm(), d.getNameEn()))
                .sorted(Comparator.comparing(DistrictResponse::nameKm, khmer))
                .toList();
    }
}
