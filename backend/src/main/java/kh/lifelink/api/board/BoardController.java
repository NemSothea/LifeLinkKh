package kh.lifelink.api.board;

import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import kh.lifelink.api.board.dto.PublicRequestResponse;
import kh.lifelink.api.common.error.ApiException;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The public board. The only unauthenticated read in this product.
 *
 * <p>Rate limited per IP because it is the one endpoint anyone on the internet can call in a loop,
 * and each call fans out across requests, matches and donor profiles. The limit protects the
 * database, not the data — the data here is public by {@code DEC-009}.
 */
@RestController
@RequestMapping("/public/requests")
public class BoardController {

    private final BoardService board;
    private final PublicBoardRateLimiter rateLimiter;

    BoardController(BoardService board, PublicBoardRateLimiter rateLimiter) {
        this.board = board;
        this.rateLimiter = rateLimiter;
    }

    @GetMapping
    List<PublicRequestResponse> openRequests(HttpServletRequest request) {
        if (!rateLimiter.tryAcquire(request.getRemoteAddr())) {
            throw ApiException.rateLimited("RATE_LIMITED", "Too many requests.");
        }
        return board.listOpenRequests();
    }
}
