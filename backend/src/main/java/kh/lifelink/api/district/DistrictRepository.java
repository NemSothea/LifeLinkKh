package kh.lifelink.api.district;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DistrictRepository extends JpaRepository<District, String> {

    Optional<District> findByCode(String code);
}
