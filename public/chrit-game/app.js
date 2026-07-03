const app = document.querySelector("#app");

const STORAGE_PREFIX = "chrit:v2";
const CATEGORIES = [
  ["all", "전체"],
  ["speed", "순발력"],
  ["brain", "두뇌"],
  ["sport", "스포츠"],
  ["party", "내기"],
];

const SPONSORS = [
  {
    id: "mavs-instagram",
    icon: "📸",
    title: "MAVS.KR 인스타",
    copy: "NBA Dallas Mavericks 팬계정",
    cta: "@mavs.kr 팔로우",
    href: "https://www.instagram.com/mavs.kr",
  },
  {
    id: "dsgnyeh-art",
    icon: "🎮",
    title: "dsgnyeh.art",
    copy: "이 게임 사이트 만든 회사.",
    cta: "dsgnyeh.art 보기",
    href: "https://dsgnyeh.art",
  },
];

const GAMES = [
  {
    id: "reaction",
    icon: "⚡",
    title: "반응속도",
    desc: "초록 화면을 보는 순간 탭하세요.",
    category: "speed",
    type: "reaction",
    tone: "cyan",
    unit: "ms",
    lowerBetter: true,
  },
  {
    id: "stop-5",
    icon: "🎯",
    title: "정밀 STOP",
    desc: "5초에 가장 가깝게 멈추세요.",
    category: "speed",
    type: "stop",
    tone: "gold",
    unit: "ms 오차",
    lowerBetter: true,
  },
  {
    id: "click-rush",
    icon: "👆",
    title: "광클 챌린지",
    desc: "5초 동안 최대한 많이 탭하세요.",
    category: "speed",
    type: "rapid",
    tone: "pink",
    unit: "회",
  },
  {
    id: "color-trap",
    icon: "🎨",
    title: "컬러 함정",
    desc: "단어가 아니라 글자색을 고르세요.",
    category: "brain",
    type: "color",
    tone: "green",
    unit: "점",
  },
  {
    id: "math-sprint",
    icon: "🧮",
    title: "암산 스프린트",
    desc: "22초 동안 빠르게 암산하세요.",
    category: "brain",
    type: "math",
    tone: "blue",
    unit: "점",
  },
  {
    id: "arrow-rush",
    icon: "➡️",
    title: "화살표 러시",
    desc: "방향을 빠르게 입력하세요.",
    category: "speed",
    type: "arrows",
    tone: "cyan",
    unit: "점",
  },
  {
    id: "sequence",
    icon: "🧠",
    title: "기억력 시퀀스",
    desc: "빛난 순서를 기억해서 따라 하세요.",
    category: "brain",
    type: "sequence",
    tone: "green",
    unit: "단계",
  },
  {
    id: "mine-roulette",
    icon: "💣",
    title: "지뢰 룰렛",
    desc: "폭탄을 피해 안전 칸을 고르세요.",
    category: "party",
    type: "mine",
    tone: "pink",
    unit: "연속",
  },
  {
    id: "free-throw",
    icon: "🏀",
    title: "드래그 자유투",
    desc: "드래그로 슛 궤적과 힘을 맞추세요.",
    category: "sport",
    type: "freeThrow",
    tone: "gold",
    unit: "점",
  },
  {
    id: "penalty",
    icon: "⚽",
    title: "승부차기",
    desc: "키퍼가 막지 못할 방향을 고르세요.",
    category: "sport",
    type: "penalty",
    tone: "green",
    unit: "골",
  },
  {
    id: "touch-roulette",
    icon: "🎲",
    title: "터치 룰렛",
    desc: "내기 당첨자를 랜덤으로 뽑으세요.",
    category: "party",
    type: "roulette",
    tone: "gold",
    unit: "번",
    recordable: false,
  },
  {
    id: "archery",
    icon: "🏹",
    title: "드래그 양궁",
    desc: "흔들리는 조준점을 정중앙에 멈추세요.",
    category: "sport",
    type: "archery",
    tone: "cyan",
    unit: "점",
  },
  {
    id: "target-smash",
    icon: "🎯",
    title: "타겟 스매시",
    desc: "나타나는 표적을 빠르게 탭하세요.",
    category: "speed",
    type: "target",
    tone: "pink",
    unit: "점",
  },
  {
    id: "rps-streak",
    icon: "✊",
    title: "가위바위보 연승",
    desc: "AI를 상대로 연승을 이어가세요.",
    category: "party",
    type: "rps",
    tone: "blue",
    unit: "연승",
  },
  {
    id: "fruit-slice",
    icon: "🍉",
    title: "과일 슬라이스",
    desc: "과일만 빠르게 잘라 점수를 올리세요.",
    category: "speed",
    type: "fruit",
    tone: "green",
    unit: "점",
  },
  {
    id: "whack-mole",
    icon: "🔨",
    title: "두더지 잡기",
    desc: "튀어나온 두더지를 놓치지 마세요.",
    category: "speed",
    type: "whack",
    tone: "gold",
    unit: "점",
  },
  {
    id: "perfect-timing",
    icon: "⏱️",
    title: "퍼펙트 타이밍",
    desc: "중앙 타이밍에 가까울수록 고득점.",
    category: "speed",
    type: "timing",
    tone: "cyan",
    unit: "점",
  },
  {
    id: "shell-game",
    icon: "🥤",
    title: "야바위 컵섞기",
    desc: "공이 든 컵을 끝까지 추적하세요.",
    category: "brain",
    type: "shell",
    tone: "pink",
    unit: "점",
  },
  {
    id: "order-tap",
    icon: "🔢",
    title: "순서대로 탭",
    desc: "1부터 9까지 순서대로 누르세요.",
    category: "brain",
    type: "ordered",
    tone: "blue",
    unit: "ms",
    lowerBetter: true,
  },
  {
    id: "memory-cards",
    icon: "🃏",
    title: "카드 짝맞추기",
    desc: "같은 그림 카드의 위치를 기억하세요.",
    category: "brain",
    type: "cards",
    tone: "green",
    unit: "회",
    lowerBetter: true,
  },
  {
    id: "odd-color",
    icon: "🟦",
    title: "다른 색 찾기",
    desc: "한 칸만 다른 색을 찾아 탭하세요.",
    category: "brain",
    type: "odd",
    tone: "cyan",
    unit: "점",
  },
  {
    id: "lifting",
    icon: "⚽",
    title: "리프팅",
    desc: "떨어지는 공을 계속 띄우세요.",
    category: "sport",
    type: "lifting",
    tone: "gold",
    unit: "회",
  },
  {
    id: "jump-rope",
    icon: "🤸",
    title: "줄넘기",
    desc: "줄이 발밑에 올 때 점프하세요.",
    category: "sport",
    type: "jump",
    tone: "green",
    unit: "점",
  },
  {
    id: "slot-timing",
    icon: "🎰",
    title: "타이밍 슬롯",
    desc: "릴을 멈춰 같은 그림을 맞추세요.",
    category: "party",
    type: "slot",
    tone: "pink",
    unit: "점",
  },
];

const state = {
  category: "all",
  route: "home",
  run: null,
};

function byId(id) {
  return document.getElementById(id);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function gameUrl(game) {
  return `${location.origin}${location.pathname}#/game/${game.id}`;
}

function sponsorUrl(sponsor, placement, gameId = "hub") {
  const url = new URL(sponsor.href);
  url.searchParams.set("utm_source", "chrit");
  url.searchParams.set("utm_medium", placement);
  url.searchParams.set("utm_campaign", gameId);
  return url.toString();
}

function getEnabledSponsors() {
  return SPONSORS.filter((sponsor) => sponsor.enabled !== false);
}

function pickResultSponsor() {
  const sponsors = getEnabledSponsors();
  if (!sponsors.length) return null;
  return sponsors[randomInt(0, sponsors.length - 1)];
}

function renderResultSponsorCta(sponsor, game) {
  if (!sponsor) return "";
  return `
    <div class="sponsor-band" style="margin-top: 18px; text-align: left;">
      <strong>${sponsor.icon} 한 판 끝났다면 다음 행동</strong>
      <p>${escapeHtml(sponsor.copy)}</p>
      <a class="secondary-action" data-sponsor="${sponsor.id}" href="${sponsorUrl(sponsor, "result_cta", game.id)}" target="_blank" rel="noopener noreferrer">
        ${escapeHtml(sponsor.cta)} ↗
      </a>
    </div>
  `;
}

function recordKey(game) {
  return `${STORAGE_PREFIX}:record:${game.id}`;
}

function getRecord(game) {
  try {
    return JSON.parse(localStorage.getItem(recordKey(game)) || "null");
  } catch {
    return null;
  }
}

function saveRecord(game, result) {
  if (game.recordable === false || result.recordable === false) {
    return { record: null, isNew: false, skipped: true };
  }

  const previous = getRecord(game);
  const isBetter =
    !previous ||
    (game.lowerBetter ? result.value < previous.value : result.value > previous.value);

  if (!isBetter) {
    return { record: previous, isNew: false };
  }

  const record = {
    value: result.value,
    label: result.label,
    at: new Date().toISOString(),
  };
  localStorage.setItem(recordKey(game), JSON.stringify(record));
  return { record, isNew: true };
}

function getAllRecords() {
  return GAMES.map((game) => ({ game, record: getRecord(game) })).filter((item) => item.record);
}

function formatValue(game, value) {
  if (game.unit === "ms" || game.unit === "ms 오차") {
    return `${Math.round(value)}${game.unit === "ms 오차" ? "ms 오차" : "ms"}`;
  }
  if (game.unit) {
    return `${Math.round(value)}${game.unit}`;
  }
  return String(value);
}

function track(name, detail = {}) {
  const payload = {
    name,
    detail,
    at: new Date().toISOString(),
  };
  window.dispatchEvent(new CustomEvent("chrit:analytics", { detail: payload }));
  try {
    const key = `${STORAGE_PREFIX}:analytics`;
    const events = JSON.parse(localStorage.getItem(key) || "[]").slice(-49);
    events.push(payload);
    localStorage.setItem(key, JSON.stringify(events));
  } catch {
    // Analytics is intentionally best effort and local only.
  }
  console.info("[chrit:analytics]", payload);
}

function cleanupRun() {
  if (!state.run) return;
  for (const timer of state.run.timers || []) {
    if (timer.type === "interval") clearInterval(timer.id);
    if (timer.type === "timeout") clearTimeout(timer.id);
  }
  if (typeof state.run.cleanup === "function") {
    state.run.cleanup();
  }
  state.run = null;
}

function createRun() {
  cleanupRun();
  state.run = { timers: [], cleanup: null };
  return state.run;
}

function addInterval(run, fn, ms) {
  const id = setInterval(fn, ms);
  run.timers.push({ id, type: "interval" });
  return id;
}

function addTimeout(run, fn, ms) {
  const id = setTimeout(fn, ms);
  run.timers.push({ id, type: "timeout" });
  return id;
}

function setApp(html) {
  app.innerHTML = html;
  window.scrollTo({ top: 0, left: 0, behavior: "auto" });
  app.focus({ preventScroll: true });
  syncNav();
}

function syncNav() {
  const route = parseRoute();
  document.querySelectorAll("[data-nav]").forEach((nav) => {
    const isCurrent =
      (nav.dataset.nav === "home" && route.name === "home") ||
      (nav.dataset.nav === "sponsors" && route.name === "sponsors") ||
      (nav.dataset.nav === "records" && route.name === "records");
    if (isCurrent) nav.setAttribute("aria-current", "page");
    else nav.removeAttribute("aria-current");
  });
}

function parseRoute() {
  const hash = location.hash || "#/";
  if (hash.startsWith("#/game/")) {
    return { name: "game", id: hash.replace("#/game/", "") };
  }
  if (hash === "#/records") return { name: "records" };
  if (hash === "#/sponsors") return { name: "sponsors" };
  return { name: "home" };
}

function renderRoute() {
  cleanupRun();
  const route = parseRoute();
  state.route = route.name;
  if (route.name === "game") {
    const game = GAMES.find((item) => item.id === route.id) || GAMES[0];
    renderGameIntro(game);
    return;
  }
  if (route.name === "records") {
    renderRecords();
    return;
  }
  if (route.name === "sponsors") {
    renderSponsors();
    return;
  }
  renderHome();
}

function renderHome() {
  const filtered =
    state.category === "all"
      ? GAMES
      : GAMES.filter((game) => game.category === state.category);
  const cards = [];
  filtered.forEach((game, index) => {
    cards.push(renderGameCard(game));
    if (state.category === "all" && index === 7) cards.push(renderSponsorCard(SPONSORS[0], "hub_grid"));
    if (state.category === "all" && index === 15) cards.push(renderSponsorCard(SPONSORS[1], "hub_grid"));
  });

  setApp(`
    <section class="hero" aria-labelledby="home-title">
      <div class="hero-copy">
        <h1 id="home-title">딱 한 판만 하고 가자</h1>
        <p>로그인 없이 바로 시작하고, 결과를 복사해 친구에게 도전장을 보내세요. 광고는 게임 흐름을 끊지 않는 네이티브 슬롯으로 배치했습니다.</p>
        <div class="hero-actions">
          <a class="primary-action" href="#/game/reaction">⚡ 바로 시작</a>
          <a class="secondary-action" href="#/records">🏆 내 기록 보기</a>
          <button class="ghost-action" type="button" data-copy-site>🔗 사이트 링크 복사</button>
        </div>
      </div>
      <div class="hero-board" aria-hidden="true">
        <div class="hero-screen"><span>⚡</span></div>
        <div class="hero-chip">결과 복사 + 스폰서 CTA</div>
      </div>
    </section>

    <section aria-labelledby="game-list-title">
      <div class="section-head">
        <div>
          <h2 id="game-list-title">게임 고르기</h2>
          <p>아래 목록은 모바일에서도 끝까지 스크롤됩니다. 각 게임은 고유 링크로 공유할 수 있습니다.</p>
        </div>
      </div>
      <div class="filter-bar" aria-label="게임 필터">
        ${CATEGORIES.map(
          ([id, label]) => `
            <button class="filter-button" type="button" data-filter="${id}" aria-pressed="${state.category === id}">
              ${label}
            </button>
          `,
        ).join("")}
      </div>
      <div class="game-grid">${cards.join("")}</div>
    </section>
  `);

  document.querySelectorAll("[data-filter]").forEach((button) => {
    button.addEventListener("click", () => {
      state.category = button.dataset.filter;
      renderHome();
    });
  });

  const copySite = document.querySelector("[data-copy-site]");
  if (copySite) {
    copySite.addEventListener("click", () => {
      copyText(`${location.origin}${location.pathname}`).then(() => showToast("사이트 링크를 복사했습니다."));
    });
  }

  bindSponsorClicks();
}

function renderGameCard(game) {
  const record = getRecord(game);
  const badge = game.recordable === false ? "내기용" : record ? `최고 ${escapeHtml(record.label)}` : "기록없음";
  return `
    <a class="game-card" data-tone="${game.tone}" href="#/game/${game.id}">
      <span class="game-icon" aria-hidden="true">${game.icon}</span>
      <strong>${escapeHtml(game.title)}</strong>
      <span>${escapeHtml(game.desc)}</span>
      <small class="record-badge">${badge}</small>
    </a>
  `;
}

function renderSponsorCard(sponsor, placement, gameId = "hub") {
  return `
    <a class="sponsor-card" data-sponsor="${sponsor.id}" href="${sponsorUrl(sponsor, placement, gameId)}" target="_blank" rel="noopener noreferrer">
      <div>
        <span class="game-icon" aria-hidden="true">${sponsor.icon}</span>
        <strong>${escapeHtml(sponsor.title)}</strong>
        <span>${escapeHtml(sponsor.copy)}</span>
      </div>
      <em>${escapeHtml(sponsor.cta)} ↗</em>
    </a>
  `;
}

function renderSponsors() {
  setApp(`
    <section class="section-head">
      <div>
        <h1>스폰서</h1>
        <p>게임하다가 잠깐 들러볼 만한 곳들입니다. 한 판 끝나고 랜덤으로 하나씩 슬쩍 나옵니다.</p>
      </div>
    </section>
    <div class="game-grid">
      ${SPONSORS.map((sponsor) => renderSponsorCard(sponsor, "sponsor_page")).join("")}
      <section class="sponsor-card">
        <div>
          <span class="game-icon" aria-hidden="true">🎲</span>
          <strong>나오는 방식</strong>
          <span>게임 목록에 살짝, 결과 화면에 랜덤으로. 플레이는 방해하지 않습니다.</span>
        </div>
        <em>한 판 끝나고 보기</em>
      </section>
      <section class="sponsor-card">
        <div>
          <span class="game-icon" aria-hidden="true">👀</span>
          <strong>등록만 하면</strong>
          <span>스폰서 목록에 넣은 링크가 결과 화면 후보가 됩니다.</span>
        </div>
        <em>가볍게 교체 가능</em>
      </section>
    </div>
  `);
  bindSponsorClicks();
}

function renderRecords() {
  const records = getAllRecords();
  setApp(`
    <section class="section-head">
      <div>
        <h1>내 기록</h1>
        <p>서버에 저장하지 않고 이 브라우저에만 남습니다. 친구에게 자랑할 때는 결과 복사를 사용하세요.</p>
      </div>
      <button class="ghost-action" type="button" data-clear-records>🧹 기록 초기화</button>
    </section>
    ${
      records.length
        ? `<div class="record-list">
            ${records
              .map(
                ({ game, record }) => `
                  <a class="record-row" href="#/game/${game.id}">
                    <div><strong>${game.icon} ${escapeHtml(game.title)}</strong><span>${new Date(record.at).toLocaleDateString("ko-KR")}</span></div>
                    <strong>${escapeHtml(record.label)}</strong>
                  </a>
                `,
              )
              .join("")}
          </div>`
        : `<div class="empty-state">아직 기록이 없습니다. 마음에 드는 게임을 한 판 시작해보세요.</div>`
    }
  `);
  const clear = document.querySelector("[data-clear-records]");
  clear?.addEventListener("click", () => {
    GAMES.forEach((game) => localStorage.removeItem(recordKey(game)));
    showToast("기록을 초기화했습니다.");
    renderRecords();
  });
}

function renderGameShell(game, innerHtml, rail = true) {
  setApp(`
    <section class="game-layout">
      <div class="game-panel">
        <div class="game-toolbar">
          <a class="small-action" href="#/">◀ 메뉴</a>
          <div class="game-title">${game.icon} ${escapeHtml(game.title)}</div>
          <button class="small-action" type="button" data-copy-game>🔗</button>
        </div>
        <div class="play-stage">${innerHtml}</div>
      </div>
      ${
        rail
          ? `<aside class="sponsor-rail" aria-label="추천 링크">
              ${renderSponsorBand(SPONSORS[0], "game_rail", game.id)}
              ${renderSponsorBand(SPONSORS[1], "game_rail", game.id)}
              <section class="sponsor-band">
                <strong>공유 팁</strong>
                <p>결과 화면에서 도발 메시지를 복사하면 친구에게 같은 게임 링크가 같이 전달됩니다.</p>
                <button class="secondary-action" type="button" data-copy-game>게임 링크 복사</button>
              </section>
            </aside>`
          : ""
      }
    </section>
  `);

  document.querySelectorAll("[data-copy-game]").forEach((button) => {
    button.addEventListener("click", () => {
      copyText(gameUrl(game)).then(() => showToast("게임 링크를 복사했습니다."));
    });
  });
  bindSponsorClicks();
}

function renderSponsorBand(sponsor, placement, gameId) {
  return `
    <section class="sponsor-band">
      <strong>${sponsor.icon} ${escapeHtml(sponsor.title)}</strong>
      <p>${escapeHtml(sponsor.copy)}</p>
      <a class="secondary-action" data-sponsor="${sponsor.id}" href="${sponsorUrl(sponsor, placement, gameId)}" target="_blank" rel="noopener noreferrer">
        ${escapeHtml(sponsor.cta)} ↗
      </a>
    </section>
  `;
}

function renderGameIntro(game) {
  renderGameShell(
    game,
    `
      <div class="intro-stage">
        <div class="intro-stack">
          <div class="intro-icon" aria-hidden="true">${game.icon}</div>
          <h1>${escapeHtml(game.title)}</h1>
          <p>${escapeHtml(game.desc)}</p>
          <div class="intro-actions">
            <button class="primary-action" type="button" data-start-game>▶ START</button>
            <button class="secondary-action" type="button" data-copy-game>친구에게 링크 복사</button>
          </div>
        </div>
      </div>
    `,
  );
  byId("app").querySelector("[data-start-game]").addEventListener("click", () => beginGame(game));
}

function beginGame(game) {
  track("game_start", { gameId: game.id, title: game.title });
  if (game.type === "reaction") return runReaction(game);
  if (game.type === "stop") return runStop(game);
  if (game.type === "rapid") return runRapid(game);
  if (game.type === "color") return runColorTrap(game);
  if (game.type === "math") return runMath(game);
  if (game.type === "arrows") return runArrows(game);
  if (game.type === "sequence") return runSequence(game);
  if (game.type === "mine") return runMine(game);
  if (game.type === "freeThrow") return runFreeThrow(game);
  if (game.type === "archery") return runArchery(game);
  if (game.type === "timing") return runTiming(game);
  if (game.type === "penalty") return runPenalty(game);
  if (game.type === "roulette") return runRoulette(game);
  if (game.type === "target") return runTarget(game);
  if (game.type === "rps") return runRps(game);
  if (game.type === "fruit") return runFruit(game);
  if (game.type === "whack") return runWhack(game);
  if (game.type === "shell") return runShell(game);
  if (game.type === "ordered") return runOrdered(game);
  if (game.type === "cards") return runCards(game);
  if (game.type === "odd") return runOddColor(game);
  if (game.type === "lifting") return runLifting(game);
  if (game.type === "jump") return runJumpRope(game);
  if (game.type === "slot") return runSlot(game);
  return runRapid(game);
}

function activeShell(game, content, stats = "") {
  renderGameShell(
    game,
    `
      <div class="active-stage">
        <div class="active-stack">
          ${stats}
          ${content}
        </div>
      </div>
    `,
    false,
  );
}

function statStrip(items) {
  return `
    <div class="stat-strip">
      ${items.map((item) => `<div><span>${item.label}</span><strong>${item.value}</strong></div>`).join("")}
    </div>
  `;
}

function finishGame(game, result) {
  cleanupRun();
  result.label = result.label || formatValue(game, result.value);
  const recordState = saveRecord(game, result);
  track("game_result", {
    gameId: game.id,
    value: result.value,
    label: result.label,
    isNew: recordState.isNew,
  });

  const sponsor = pickResultSponsor();
  const shareText = makeShareText(game, result, recordState.isNew);
  const recordLine = recordState.skipped
    ? "이 결과는 랜덤 또는 무효 결과라 최고 기록에 저장하지 않습니다."
    : `내 최고 기록: <strong>${escapeHtml(recordState.record.label)}</strong>`;
  renderGameShell(
    game,
    `
      <div class="result-stage">
        <section class="result-panel">
          <h1>${recordState.isNew ? "신기록!" : "결과"}</h1>
          <div class="result-score">${escapeHtml(result.label)}</div>
          <p>${escapeHtml(result.message || gradeMessage(game, result.value))}</p>
          <p>${recordLine}</p>
          <div class="result-actions">
            <button class="primary-action" type="button" data-retry>다시하기</button>
            <a class="secondary-action" href="#/">메뉴</a>
            <button class="ghost-action" type="button" data-share-result>📋 도발 메시지 복사</button>
          </div>
          ${renderResultSponsorCta(sponsor, game)}
        </section>
      </div>
    `,
  );
  if (sponsor) {
    track("ad_impression", { sponsorId: sponsor.id, placement: "result_cta", gameId: game.id });
  }
  byId("app").querySelector("[data-retry]").addEventListener("click", () => beginGame(game));
  byId("app").querySelector("[data-share-result]").addEventListener("click", () => {
    copyText(shareText).then(() => {
      track("share_copy", { gameId: game.id, label: result.label });
      showToast("도발 메시지를 복사했습니다.");
    });
  });
  bindSponsorClicks();
}

function gradeMessage(game, value) {
  if (game.lowerBetter) return value < 500 ? "손이 꽤 빠른데요." : "한 번 더 하면 바로 줄일 수 있습니다.";
  if (value >= 80) return "이 정도면 동료에게 바로 보내도 됩니다.";
  if (value >= 30) return "좋습니다. 다시하면 더 올라갑니다.";
  return "몸풀기 완료. 한 번 더 갑시다.";
}

function makeShareText(game, result, isNew) {
  const title = isNew ? "신기록 찍음" : "한 판 붙자";
  return `[찌릿] ${game.title} ${result.label} - ${title}\n${gameUrl(game)}`;
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function shuffle(items) {
  return [...items].sort(() => Math.random() - 0.5);
}

function runReaction(game) {
  const run = createRun();
  let ready = false;
  let startedAt = 0;
  activeShell(
    game,
    `
      <h2 class="active-title">기다려...</h2>
      <p class="active-subtitle">초록색이 되면 바로 탭하세요. 성급하면 실패입니다.</p>
      <button class="big-hit-zone" type="button" data-reaction-zone>
        <span class="tap-count">⚡</span>
      </button>
    `,
  );
  const zone = byId("app").querySelector("[data-reaction-zone]");
  zone.addEventListener("click", () => {
    if (!ready) {
      finishGame(game, { value: 9999, label: "실패", recordable: false, message: "초록 전에 눌렀습니다. 다시 참아보세요." });
      return;
    }
    finishGame(game, { value: performance.now() - startedAt });
  });
  addTimeout(
    run,
    () => {
      ready = true;
      startedAt = performance.now();
      zone.classList.add("ready");
      zone.querySelector(".tap-count").textContent = "지금!";
      byId("app").querySelector(".active-title").textContent = "탭!";
    },
    randomInt(1100, 2600),
  );
}

function runStop(game) {
  const run = createRun();
  const startedAt = performance.now();
  activeShell(
    game,
    `
      <h2 class="active-title" data-time>0.000초</h2>
      <p class="active-subtitle">5.000초에 최대한 가깝게 멈추세요.</p>
      <button class="primary-action" type="button" data-stop>STOP</button>
    `,
  );
  const time = byId("app").querySelector("[data-time]");
  addInterval(run, () => {
    time.textContent = `${((performance.now() - startedAt) / 1000).toFixed(3)}초`;
  }, 32);
  byId("app").querySelector("[data-stop]").addEventListener("click", () => {
    const elapsed = performance.now() - startedAt;
    const error = Math.abs(5000 - elapsed);
    finishGame(game, { value: error, message: `${(elapsed / 1000).toFixed(3)}초에 멈췄습니다.` });
  });
}

function runRapid(game) {
  const run = createRun();
  let count = 0;
  let left = 5;
  activeShell(
    game,
    `
      <h2 class="active-title">미친 연타</h2>
      <p class="active-subtitle">5초 동안 버튼 안을 최대한 많이 탭하세요.</p>
      <button class="big-hit-zone" type="button" data-rapid>
        <span class="tap-count" data-count>0</span>
      </button>
    `,
    statStrip([
      { label: "남은 시간", value: "5.0초" },
      { label: "현재", value: "0회" },
      { label: "목표", value: "50회" },
    ]),
  );
  const countEl = byId("app").querySelector("[data-count]");
  const stats = byId("app").querySelectorAll(".stat-strip strong");
  byId("app").querySelector("[data-rapid]").addEventListener("click", () => {
    count += 1;
    countEl.textContent = count;
    stats[1].textContent = `${count}회`;
  });
  addInterval(run, () => {
    left -= 0.1;
    stats[0].textContent = `${Math.max(0, left).toFixed(1)}초`;
    if (left <= 0) finishGame(game, { value: count });
  }, 100);
}

function runColorTrap(game) {
  const colors = [
    { name: "빨강", value: "#ff6b5f" },
    { name: "노랑", value: "#ffd34d" },
    { name: "초록", value: "#7ad66d" },
    { name: "파랑", value: "#73a7ff" },
  ];
  let round = 0;
  let score = 0;
  const run = createRun();
  const next = () => {
    if (round >= 10) return finishGame(game, { value: score });
    round += 1;
    const word = colors[randomInt(0, colors.length - 1)];
    const ink = shuffle(colors.filter((color) => color.name !== word.name))[0];
    activeShell(
      game,
      `
        <h2 class="active-title" style="color:${ink.value}">${word.name}</h2>
        <p class="active-subtitle">단어 뜻 말고, 글자색을 고르세요.</p>
        <div class="choice-grid">
          ${shuffle(colors)
            .map((color) => `<button class="choice-button" type="button" data-color="${color.name}">${color.name}</button>`)
            .join("")}
        </div>
      `,
      statStrip([
        { label: "라운드", value: `${round}/10` },
        { label: "점수", value: `${score}` },
        { label: "정답", value: "글자색" },
      ]),
    );
    byId("app").querySelectorAll("[data-color]").forEach((button) => {
      button.addEventListener("click", () => {
        if (button.dataset.color === ink.name) score += 10;
        addTimeout(run, next, 120);
      });
    });
  };
  next();
}

function runMath(game) {
  const run = createRun();
  let score = 0;
  let left = 22;
  const stats = () =>
    statStrip([
      { label: "남은 시간", value: `${left}초` },
      { label: "점수", value: `${score}` },
      { label: "방식", value: "암산" },
    ]);
  const next = () => {
    const a = randomInt(7, 29);
    const b = randomInt(3, 18);
    const op = Math.random() > 0.5 ? "+" : "-";
    const answer = op === "+" ? a + b : a - b;
    const optionSet = new Set([answer]);
    while (optionSet.size < 4) {
      const offset = randomInt(-10, 10);
      if (offset !== 0) optionSet.add(answer + offset);
    }
    const options = shuffle([...optionSet]);
    activeShell(
      game,
      `
        <h2 class="active-title">${a} ${op} ${b}</h2>
        <p class="active-subtitle">정답을 고르세요.</p>
        <div class="choice-grid">
          ${options.map((value) => `<button class="choice-button" type="button" data-answer="${value}">${value}</button>`).join("")}
        </div>
      `,
      stats(),
    );
    byId("app").querySelectorAll("[data-answer]").forEach((button) => {
      button.addEventListener("click", () => {
        if (Number(button.dataset.answer) === answer) score += 1;
        next();
      });
    });
  };
  addInterval(run, () => {
    left -= 1;
    if (left <= 0) finishGame(game, { value: score });
    else byId("app").querySelector(".stat-strip strong").textContent = `${left}초`;
  }, 1000);
  next();
}

function runArrows(game) {
  const run = createRun();
  const arrows = [
    ["ArrowUp", "↑"],
    ["ArrowDown", "↓"],
    ["ArrowLeft", "←"],
    ["ArrowRight", "→"],
  ];
  let score = 0;
  let round = 0;
  let left = 12;
  let current = arrows[0];
  let promptStartedAt = 0;
  let ended = false;

  const end = (message = "제한 시간이 끝났습니다.") => {
    if (ended) return;
    ended = true;
    finishGame(game, { value: score, message });
  };

  const next = (feedback = "빠르게 같은 방향을 누르세요.") => {
    if (ended) return;
    if (round >= 16) return end("모든 방향을 처리했습니다.");
    round += 1;
    current = arrows[randomInt(0, arrows.length - 1)];
    promptStartedAt = performance.now();
    activeShell(
      game,
      `
        <h2 class="active-title">${current[1]}</h2>
        <p class="active-subtitle">${feedback}</p>
        <div class="choice-grid">
          ${arrows.map(([key, label]) => `<button class="choice-button" type="button" data-arrow="${key}">${label}</button>`).join("")}
        </div>
      `,
      statStrip([
        { label: "남은 시간", value: `${left.toFixed(1)}초` },
        { label: "라운드", value: `${round}/16` },
        { label: "점수", value: `${score}` },
      ]),
    );
    byId("app").querySelectorAll("[data-arrow]").forEach((button) => {
      button.addEventListener("click", () => handle(button.dataset.arrow));
    });
  };

  const handle = (key) => {
    if (!current || ended) return;
    const elapsed = performance.now() - promptStartedAt;
    const correct = key === current[0];
    const gain = correct ? Math.max(1, Math.round(10 - elapsed / 145)) : 0;
    if (correct) score += gain;
    current = null;
    next(correct ? `+${gain}점. 속도 좋습니다.` : "방향이 빗나갔습니다.");
  };

  const onKey = (event) => {
    if (arrows.some(([key]) => key === event.key)) handle(event.key);
  };

  window.addEventListener("keydown", onKey);
  run.cleanup = () => window.removeEventListener("keydown", onKey);
  addInterval(run, () => {
    left = Math.max(0, left - 0.1);
    const timeEl = byId("app")?.querySelector(".stat-strip strong");
    if (timeEl) timeEl.textContent = `${left.toFixed(1)}초`;
    if (left <= 0) end();
  }, 100);
  next();
}

function runSequence(game) {
  const pads = ["🟨", "🟩", "🟦", "🟥"];
  const run = createRun();
  const sequence = [];
  let level = 1;
  const maxLevel = 8;

  const showSequence = () => {
    while (sequence.length < level) {
      sequence.push(randomInt(0, 3));
    }
    activeShell(
      game,
      `
        <h2 class="active-title">${level}단계 기억</h2>
        <p class="active-subtitle">순서를 보고 그대로 따라 누르세요.</p>
        <div class="tile-grid" style="--cols: ${Math.min(level, 4)};">
          ${sequence.map((i) => `<div class="tile-button sequence-preview">${pads[i]}</div>`).join("")}
        </div>
      `,
      statStrip([
        { label: "단계", value: `${level}/${maxLevel}` },
        { label: "길이", value: `${sequence.length}` },
        { label: "목표", value: "기억" },
      ]),
    );
    addTimeout(run, promptSequence, Math.min(900 + level * 260, 2600));
  };

  const promptSequence = () => {
    let index = 0;
    activeShell(
      game,
      `
        <h2 class="active-title">따라 누르기</h2>
        <p class="active-subtitle">${index + 1}/${sequence.length}번째 입력</p>
        <div class="tile-grid" style="--cols: 2;">
          ${pads.map((pad, i) => `<button class="tile-button" type="button" data-pad="${i}">${pad}</button>`).join("")}
        </div>
      `,
      statStrip([
        { label: "단계", value: `${level}/${maxLevel}` },
        { label: "성공", value: `${Math.max(0, level - 1)}단계` },
        { label: "입력", value: "순서" },
      ]),
    );
    byId("app").querySelectorAll("[data-pad]").forEach((button) => {
      button.addEventListener("click", () => {
        if (Number(button.dataset.pad) !== sequence[index]) {
          finishGame(game, { value: level - 1, message: `${level - 1}단계까지 성공했습니다.` });
          return;
        }
        index += 1;
        if (index >= sequence.length) {
          if (level >= maxLevel) {
            finishGame(game, { value: level, message: "최종 단계까지 모두 기억했습니다." });
            return;
          }
          level += 1;
          addTimeout(run, showSequence, 420);
        } else {
          byId("app").querySelector(".active-subtitle").textContent = `${index + 1}/${sequence.length}번째 입력`;
        }
      });
    });
  };

  showSequence();
}

function runMine(game) {
  const run = createRun();
  let score = 0;
  const next = () => {
    const bomb = randomInt(0, 3);
    activeShell(
      game,
      `
        <h2 class="active-title">폭탄 피하기</h2>
        <p class="active-subtitle">안전하다고 믿는 칸을 고르세요.</p>
        <div class="tile-grid" style="--cols: 2;">
          ${[0, 1, 2, 3].map((i) => `<button class="tile-button" type="button" data-mine="${i}">?</button>`).join("")}
        </div>
      `,
      statStrip([
        { label: "연속 성공", value: `${score}` },
        { label: "위험", value: "1/4" },
        { label: "목표", value: "생존" },
      ]),
    );
    byId("app").querySelectorAll("[data-mine]").forEach((button) => {
      button.addEventListener("click", () => {
        byId("app").querySelectorAll("[data-mine]").forEach((item) => {
          item.disabled = true;
        });
        if (Number(button.dataset.mine) === bomb) {
          button.textContent = "💣";
          button.classList.add("wrong");
          finishGame(game, { value: score, message: "폭탄을 밟았습니다." });
          return;
        }
        score += 1;
        button.textContent = "✅";
        button.classList.add("correct");
        addTimeout(run, next, 240);
      });
    });
  };
  next();
}

function runFreeThrow(game) {
  runDragPrecision(game, {
    title: "공을 위로 끌어 슛",
    subtitle: "짧게 끌면 약하고, 옆으로 틀면 빗나갑니다.",
    target: "🏀",
    mode: "vector",
    ideal: { x: 0, y: -155 },
    message: (score) => (score >= 75 ? "림 안쪽으로 깔끔하게 들어갔습니다." : "궤적과 힘을 조금 더 맞춰보세요."),
  });
}

function runArchery(game) {
  runDragPrecision(game, {
    title: "중앙에 조준",
    subtitle: "드래그 끝점이 과녁 중앙에 가까울수록 고득점입니다.",
    target: "◎",
    mode: "point",
    message: (score) => (score >= 80 ? "정중앙에 가깝습니다." : "호흡을 가다듬고 조금 더 중앙으로."),
  });
}

function runDragPrecision(game, options) {
  const run = createRun();
  activeShell(
    game,
    `
      <h2 class="active-title">${options.title}</h2>
      <p class="active-subtitle">${options.subtitle}</p>
      <div class="drag-arena" data-drag-arena>
        <div class="target-ring" aria-hidden="true">${options.target}</div>
        <div class="drag-line" data-drag-line></div>
        <div class="drag-dot" data-drag-dot></div>
        <span class="drag-hint">누르고 끌어서 놓기</span>
      </div>
    `,
  );

  const arena = byId("app").querySelector("[data-drag-arena]");
  const line = byId("app").querySelector("[data-drag-line]");
  const dot = byId("app").querySelector("[data-drag-dot]");
  let start = null;
  let current = null;

  const pointFromEvent = (event) => {
    const rect = arena.getBoundingClientRect();
    return {
      x: Math.max(0, Math.min(rect.width, event.clientX - rect.left)),
      y: Math.max(0, Math.min(rect.height, event.clientY - rect.top)),
      rect,
    };
  };

  const updateLine = () => {
    if (!start || !current) return;
    const dx = current.x - start.x;
    const dy = current.y - start.y;
    const length = Math.hypot(dx, dy);
    const angle = Math.atan2(dy, dx) * (180 / Math.PI);
    line.style.width = `${length}px`;
    line.style.transform = `translate(${start.x}px, ${start.y}px) rotate(${angle}deg)`;
    dot.style.transform = `translate(${current.x}px, ${current.y}px)`;
    arena.classList.add("dragging");
  };

  const onDown = (event) => {
    start = pointFromEvent(event);
    current = start;
    updateLine();
  };
  const onMove = (event) => {
    if (!start) return;
    current = pointFromEvent(event);
    updateLine();
  };
  const onUp = (event) => {
    if (!start) return;
    current = pointFromEvent(event);
    const dx = current.x - start.x;
    const dy = current.y - start.y;
    const length = Math.hypot(dx, dy);
    if (length < 24) {
      showToast("조금 더 길게 드래그해보세요.");
      start = null;
      current = null;
      arena.classList.remove("dragging");
      line.style.width = "0";
      return;
    }

    let score;
    if (options.mode === "point") {
      const cx = current.rect.width / 2;
      const cy = current.rect.height / 2;
      const distance = Math.hypot(current.x - cx, current.y - cy);
      score = Math.max(0, Math.round(100 - distance * 0.9));
    } else {
      const error = Math.abs(dx - options.ideal.x) * 0.72 + Math.abs(dy - options.ideal.y) * 0.58;
      score = Math.max(0, Math.round(100 - error));
    }
    finishGame(game, { value: score, message: options.message(score) });
  };

  arena.addEventListener("pointerdown", onDown);
  window.addEventListener("pointermove", onMove);
  window.addEventListener("pointerup", onUp);
  run.cleanup = () => {
    arena.removeEventListener("pointerdown", onDown);
    window.removeEventListener("pointermove", onMove);
    window.removeEventListener("pointerup", onUp);
  };
}

function runTiming(game) {
  const run = createRun();
  let pos = 0;
  let dir = 1;
  activeShell(
    game,
    `
      <h2 class="active-title">중앙에 멈추기</h2>
      <p class="active-subtitle">흰 바늘이 가운데 초록 영역에 왔을 때 멈추세요.</p>
      <div class="meter"><span class="meter-needle" style="--pos:0"></span></div>
      <button class="primary-action" type="button" data-hit>멈추기</button>
    `,
  );
  const needle = byId("app").querySelector(".meter-needle");
  addInterval(run, () => {
    pos += dir * 2.4;
    if (pos >= 100 || pos <= 0) dir *= -1;
    pos = Math.max(0, Math.min(100, pos));
    needle.style.setProperty("--pos", pos);
  }, 24);
  byId("app").querySelector("[data-hit]").addEventListener("click", () => {
    const score = Math.max(0, Math.round(100 - Math.abs(50 - pos) * 2));
    finishGame(game, { value: score, message: `중앙에서 ${Math.abs(50 - pos).toFixed(1)}만큼 벗어났습니다.` });
  });
}

function runPenalty(game) {
  const run = createRun();
  const choices = ["왼쪽", "가운데", "오른쪽"];
  let score = 0;
  let round = 0;
  const next = () => {
    if (round >= 5) return finishGame(game, { value: score });
    round += 1;
    const keeper = choices[randomInt(0, 2)];
    const hint = choices.filter((choice) => choice !== keeper)[randomInt(0, 1)];
    const hintParticle = hint === "가운데" ? "를" : "을";
    activeShell(
      game,
      `
        <h2 class="active-title">어디로 찰까?</h2>
        <p class="active-subtitle">키퍼가 ${hint}${hintParticle} 힐끔 봅니다. 속임수일 수도 있어요.</p>
        <div class="penalty-field">
          <div class="penalty-goal">
            <span>왼쪽</span>
            <span class="penalty-keeper">🧤</span>
            <span>오른쪽</span>
          </div>
        </div>
        <div class="choice-grid penalty-choices">
          ${choices.map((choice) => `<button class="choice-button" type="button" data-shot="${choice}">${choice}</button>`).join("")}
        </div>
      `,
      statStrip([
        { label: "라운드", value: `${round}/5` },
        { label: "골", value: `${score}` },
        { label: "힌트", value: hint },
      ]),
    );
    const title = byId("app").querySelector(".active-title");
    const subtitle = byId("app").querySelector(".active-subtitle");
    const stats = byId("app").querySelectorAll(".stat-strip strong");
    const keeperEl = byId("app").querySelector(".penalty-keeper");
    byId("app").querySelectorAll("[data-shot]").forEach((button) => {
      let handled = false;
      const shoot = () => {
        if (handled) return;
        handled = true;
        byId("app").querySelectorAll("[data-shot]").forEach((item) => {
          item.disabled = true;
        });
        const goal = button.dataset.shot !== keeper;
        if (goal) score += 1;
        button.classList.add(goal ? "correct" : "wrong");
        title.textContent = goal ? "골!" : "선방";
        subtitle.textContent = `키퍼는 ${keeper}으로 몸을 날렸습니다.`;
        keeperEl.textContent = keeper === "왼쪽" ? "🧤⬅" : keeper === "오른쪽" ? "➡🧤" : "⬇🧤";
        stats[1].textContent = `${score}`;
        addTimeout(run, next, 720);
      };
      button.addEventListener("pointerdown", shoot);
      button.addEventListener("mousedown", shoot);
      button.addEventListener("click", shoot);
    });
  };
  next();
}

function runRoulette(game) {
  let players = 4;
  const render = () => {
    activeShell(
      game,
      `
        <h2 class="active-title">${players}명</h2>
        <p class="active-subtitle">참여 인원을 맞춘 뒤 당첨자를 뽑으세요.</p>
        <div class="intro-actions">
          <button class="secondary-action" type="button" data-minus>−</button>
          <button class="secondary-action" type="button" data-plus>+</button>
          <button class="primary-action" type="button" data-draw>뽑기</button>
        </div>
      `,
    );
    byId("app").querySelector("[data-minus]").addEventListener("click", () => {
      players = Math.max(2, players - 1);
      render();
    });
    byId("app").querySelector("[data-plus]").addEventListener("click", () => {
      players = Math.min(12, players + 1);
      render();
    });
    byId("app").querySelector("[data-draw]").addEventListener("click", () => {
      const winner = randomInt(1, players);
      finishGame(game, { value: winner, label: `${winner}번`, message: `${players}명 중 ${winner}번 당첨입니다.` });
    });
  };
  render();
}

function runJumpRope(game) {
  const run = createRun();
  let phase = 0;
  let dir = 1;
  let score = 0;
  let misses = 0;
  let left = 20;
  activeShell(
    game,
    `
      <h2 class="active-title">줄이 발밑에 올 때</h2>
      <p class="active-subtitle">바늘이 초록 구간에 들어왔을 때 점프하세요. 실수 3번이면 종료.</p>
      <div class="meter"><span class="meter-needle" style="--pos:0"></span></div>
      <button class="primary-action" type="button" data-jump>JUMP</button>
    `,
    statStrip([
      { label: "남은 시간", value: `${left}초` },
      { label: "성공", value: "0회" },
      { label: "실수", value: "0/3" },
    ]),
  );
  const needle = byId("app").querySelector(".meter-needle");
  const stats = byId("app").querySelectorAll(".stat-strip strong");
  addInterval(run, () => {
    phase += dir * 3.4;
    if (phase >= 100 || phase <= 0) dir *= -1;
    phase = Math.max(0, Math.min(100, phase));
    needle.style.setProperty("--pos", phase);
  }, 24);
  addInterval(run, () => {
    left -= 1;
    stats[0].textContent = `${left}초`;
    if (left <= 0) finishGame(game, { value: score });
  }, 1000);
  byId("app").querySelector("[data-jump]").addEventListener("click", () => {
    const good = phase >= 44 && phase <= 56;
    if (good) {
      score += 1;
      stats[1].textContent = `${score}회`;
      return;
    }
    misses += 1;
    stats[2].textContent = `${misses}/3`;
    if (misses >= 3) finishGame(game, { value: score, message: "타이밍을 세 번 놓쳤습니다." });
  });
}

function runTarget(game) {
  runGridTap(game, {
    icon: "🎯",
    seconds: 15,
    cols: 3,
    missIcon: "·",
    title: "표적 탭",
  });
}

function runFruit(game) {
  const run = createRun();
  const fruits = ["🍉", "🍋", "🍓", "🍍", "🍇"];
  let score = 0;
  let left = 18;
  let lives = 3;
  let slicing = false;
  let nextId = 0;

  activeShell(
    game,
    `
      <h2 class="active-title">과일 슬라이스</h2>
      <p class="active-subtitle">화면을 그어서 과일만 자르세요. 폭탄을 자르면 실수입니다.</p>
      <div class="slice-arena" data-slice-arena>
        <div class="slice-trail" data-slice-trail></div>
      </div>
    `,
    statStrip([
      { label: "남은 시간", value: `${left}초` },
      { label: "점수", value: "0점" },
      { label: "실수", value: "0/3" },
    ]),
  );

  const arena = byId("app").querySelector("[data-slice-arena]");
  const trail = byId("app").querySelector("[data-slice-trail]");
  const stats = byId("app").querySelectorAll(".stat-strip strong");

  const updateStats = () => {
    stats[0].textContent = `${left}초`;
    stats[1].textContent = `${score}점`;
    stats[2].textContent = `${3 - lives}/3`;
  };

  const removeItem = (item) => {
    if (!item?.isConnected) return;
    item.remove();
  };

  const spawn = () => {
    if (!arena?.isConnected) return;
    const isBomb = Math.random() < 0.24;
    const item = document.createElement("span");
    item.className = `slice-item${isBomb ? " bomb" : ""}`;
    item.dataset.kind = isBomb ? "bomb" : "fruit";
    item.dataset.id = String(nextId++);
    item.textContent = isBomb ? "💣" : fruits[randomInt(0, fruits.length - 1)];
    item.style.left = `${randomInt(10, 86)}%`;
    item.style.top = `${randomInt(14, 78)}%`;
    arena.appendChild(item);
    addTimeout(run, () => removeItem(item), 2300);
  };

  const point = (event) => ({ x: event.clientX, y: event.clientY });
  const checkSlice = (event) => {
    if (!slicing) return;
    const p = point(event);
    trail.style.transform = `translate(${p.x - arena.getBoundingClientRect().left}px, ${p.y - arena.getBoundingClientRect().top}px)`;
    arena.querySelectorAll(".slice-item").forEach((item) => {
      const rect = item.getBoundingClientRect();
      const inside = p.x >= rect.left && p.x <= rect.right && p.y >= rect.top && p.y <= rect.bottom;
      if (!inside || item.dataset.sliced === "true") return;
      item.dataset.sliced = "true";
      item.classList.add("sliced");
      if (item.dataset.kind === "bomb") {
        lives -= 1;
        item.classList.add("wrong");
        if (lives <= 0) {
          finishGame(game, { value: score, message: "폭탄을 세 번 건드렸습니다." });
          return;
        }
      } else {
        score += 10;
        item.classList.add("correct");
      }
      updateStats();
      addTimeout(run, () => removeItem(item), 160);
    });
  };

  const onDown = (event) => {
    slicing = true;
    arena.classList.add("slicing");
    checkSlice(event);
  };
  const onMove = (event) => checkSlice(event);
  const onUp = () => {
    slicing = false;
    arena.classList.remove("slicing");
  };

  arena.addEventListener("pointerdown", onDown);
  window.addEventListener("pointermove", onMove);
  window.addEventListener("pointerup", onUp);
  run.cleanup = () => {
    arena.removeEventListener("pointerdown", onDown);
    window.removeEventListener("pointermove", onMove);
    window.removeEventListener("pointerup", onUp);
  };

  addInterval(run, spawn, 620);
  addInterval(run, () => {
    left -= 1;
    updateStats();
    if (left <= 0) finishGame(game, { value: score });
  }, 1000);
  spawn();
}

function runWhack(game) {
  runGridTap(game, {
    icon: "🦫",
    seconds: 12,
    cols: 3,
    missIcon: "·",
    title: "나온 곳을 탭",
  });
}

function runLifting(game) {
  const run = createRun();
  let y = 8;
  let speed = 1.7;
  let score = 0;
  let misses = 0;
  activeShell(
    game,
    `
      <h2 class="active-title">공이 낮을 때 차기</h2>
      <p class="active-subtitle">공이 초록 구간에 들어오면 리프팅하세요. 너무 빠르거나 늦으면 실수입니다.</p>
      <div class="ball-stage">
        <div class="kick-zone">KICK ZONE</div>
        <div class="moving-ball" data-ball>⚽</div>
      </div>
      <button class="primary-action" type="button" data-lift>리프팅</button>
    `,
    statStrip([
      { label: "성공", value: "0회" },
      { label: "실수", value: "0/3" },
      { label: "목표", value: "공 유지" },
    ]),
  );
  const ball = byId("app").querySelector("[data-ball]");
  const stats = byId("app").querySelectorAll(".stat-strip strong");
  const miss = () => {
    misses += 1;
    stats[1].textContent = `${misses}/3`;
    y = 8;
    speed += 0.12;
    if (misses >= 3) finishGame(game, { value: score, message: "공을 세 번 떨어뜨렸습니다." });
  };
  addInterval(run, () => {
    y += speed;
    ball.style.top = `${y}%`;
    if (y >= 104) miss();
  }, 34);
  byId("app").querySelector("[data-lift]").addEventListener("click", () => {
    if (y >= 66 && y <= 88) {
      score += 1;
      stats[0].textContent = `${score}회`;
      y = 8;
      speed = Math.min(3.8, speed + 0.14);
      return;
    }
    miss();
  });
}

function runGridTap(game, options) {
  const run = createRun();
  let score = 0;
  let left = options.seconds;
  let target = randomInt(0, options.cols * options.cols - 1);
  const draw = () => {
    activeShell(
      game,
      `
        <h2 class="active-title">${options.title}</h2>
        <p class="active-subtitle">정답 칸을 빠르게 누르세요.</p>
        <div class="tile-grid" style="--cols:${options.cols};">
          ${Array.from({ length: options.cols * options.cols }, (_, i) => {
            const label = i === target ? options.icon : options.missIcon;
            return `<button class="tile-button" type="button" data-cell="${i}">${label}</button>`;
          }).join("")}
        </div>
      `,
      statStrip([
        { label: "남은 시간", value: `${left}초` },
        { label: "점수", value: `${score}` },
        { label: "목표", value: options.icon },
      ]),
    );
    byId("app").querySelectorAll("[data-cell]").forEach((button) => {
      button.addEventListener("click", () => {
        const hit = Number(button.dataset.cell) === target;
        if (hit) score += 1;
        else if (options.avoidMiss) score = Math.max(0, score - 1);
        target = randomInt(0, options.cols * options.cols - 1);
        draw();
      });
    });
  };
  addInterval(run, () => {
    left -= 1;
    if (left <= 0) finishGame(game, { value: score });
    else {
      const first = byId("app")?.querySelector(".stat-strip strong");
      if (first) first.textContent = `${left}초`;
    }
  }, 1000);
  draw();
}

function runRps(game) {
  const hands = [
    ["rock", "✊"],
    ["scissors", "✌️"],
    ["paper", "✋"],
  ];
  const beats = { rock: "scissors", scissors: "paper", paper: "rock" };
  let streak = 0;
  const next = () => {
    const ai = hands[randomInt(0, 2)];
    activeShell(
      game,
      `
        <h2 class="active-title">AI를 이겨라</h2>
        <p class="active-subtitle">비기거나 지면 종료됩니다.</p>
        <div class="choice-grid">
          ${hands.map(([id, label]) => `<button class="choice-button" type="button" data-hand="${id}">${label}</button>`).join("")}
        </div>
      `,
      statStrip([
        { label: "연승", value: `${streak}` },
        { label: "상대", value: "비공개" },
        { label: "목표", value: "승리" },
      ]),
    );
    byId("app").querySelectorAll("[data-hand]").forEach((button) => {
      button.addEventListener("click", () => {
        const pick = button.dataset.hand;
        if (beats[pick] === ai[0]) {
          streak += 1;
          next();
        } else {
          finishGame(game, { value: streak, message: `AI는 ${ai[1]}를 냈습니다.` });
        }
      });
    });
  };
  next();
}

function runShell(game) {
  const run = createRun();
  let score = 0;
  let round = 0;
  const next = () => {
    if (round >= 5) return finishGame(game, { value: score * 20, label: `${score}/5` });
    round += 1;
    const ball = randomInt(0, 2);
    activeShell(
      game,
      `
        <h2 class="active-title">위치 기억</h2>
        <p class="active-subtitle">공이 보인 컵을 기억하세요. 곧 섞입니다.</p>
        <div class="tile-grid" style="--cols:3;">
          ${[0, 1, 2].map((i) => `<div class="tile-button">${i === ball ? "⚪" : "🥤"}</div>`).join("")}
        </div>
      `,
      statStrip([
        { label: "라운드", value: `${round}/5` },
        { label: "정답", value: `${score}` },
        { label: "집중", value: "컵" },
      ]),
    );
    addTimeout(run, () => {
      activeShell(
        game,
        `
          <h2 class="active-title">섞는 중...</h2>
          <p class="active-subtitle">마지막 위치를 고르세요.</p>
          <div class="tile-grid" style="--cols:3;">
            ${[0, 1, 2].map((i) => `<button class="tile-button" type="button" data-cup="${i}">🥤</button>`).join("")}
          </div>
        `,
        statStrip([
          { label: "라운드", value: `${round}/5` },
          { label: "정답", value: `${score}` },
          { label: "집중", value: "위치" },
        ]),
      );
      byId("app").querySelectorAll("[data-cup]").forEach((button) => {
        button.addEventListener("click", () => {
          byId("app").querySelectorAll("[data-cup]").forEach((item) => {
            item.disabled = true;
          });
          if (Number(button.dataset.cup) === ball) {
            score += 1;
            button.textContent = "⚪";
            button.classList.add("correct");
          } else {
            button.textContent = "빈 컵";
            button.classList.add("wrong");
          }
          addTimeout(run, next, 320);
        });
      });
    }, 900);
  };
  next();
}

function runOrdered(game) {
  const start = performance.now();
  let nextNumber = 1;
  const numbers = shuffle([1, 2, 3, 4, 5, 6, 7, 8, 9]);
  activeShell(
    game,
    `
      <h2 class="active-title">1부터 9까지</h2>
      <p class="active-subtitle">순서대로 빠르게 누르세요.</p>
      <div class="tile-grid" style="--cols:3;">
        ${numbers.map((n) => `<button class="tile-button" type="button" data-number="${n}">${n}</button>`).join("")}
      </div>
    `,
  );
  byId("app").querySelectorAll("[data-number]").forEach((button) => {
    button.addEventListener("click", () => {
      if (Number(button.dataset.number) !== nextNumber) {
        button.classList.add("wrong");
        return;
      }
      button.classList.add("correct");
      button.disabled = true;
      nextNumber += 1;
      if (nextNumber > 9) finishGame(game, { value: performance.now() - start });
    });
  });
}

function runCards(game) {
  const icons = shuffle(["🍒", "🍒", "🍋", "🍋", "🍇", "🍇", "⭐", "⭐"]);
  let opened = [];
  let matched = 0;
  let tries = 0;
  activeShell(
    game,
    `
      <h2 class="active-title">짝 맞추기</h2>
      <p class="active-subtitle">같은 그림 두 장을 찾으세요.</p>
      <div class="tile-grid" style="--cols:4;">
        ${icons.map((icon, i) => `<button class="tile-button" type="button" data-card="${i}" data-icon="${icon}">?</button>`).join("")}
      </div>
    `,
    statStrip([
      { label: "시도", value: "0회" },
      { label: "짝", value: "0/4" },
      { label: "목표", value: "적은 시도" },
    ]),
  );
  const stat = byId("app").querySelectorAll(".stat-strip strong");
  byId("app").querySelectorAll("[data-card]").forEach((button) => {
    button.addEventListener("click", () => {
      if (button.disabled || opened.includes(button)) return;
      button.textContent = button.dataset.icon;
      opened.push(button);
      if (opened.length < 2) return;
      tries += 1;
      stat[0].textContent = `${tries}회`;
      const [a, b] = opened;
      if (a.dataset.icon === b.dataset.icon) {
        a.disabled = true;
        b.disabled = true;
        a.classList.add("correct");
        b.classList.add("correct");
        matched += 1;
        stat[1].textContent = `${matched}/4`;
        opened = [];
        if (matched === 4) finishGame(game, { value: tries });
        return;
      }
      setTimeout(() => {
        a.textContent = "?";
        b.textContent = "?";
        opened = [];
      }, 520);
    });
  });
}

function runOddColor(game) {
  const run = createRun();
  let score = 0;
  let left = 20;
  const draw = () => {
    const odd = randomInt(0, 15);
    const hue = randomInt(0, 360);
    activeShell(
      game,
      `
        <h2 class="active-title">한 칸만 다름</h2>
        <p class="active-subtitle">미세하게 다른 색을 찾으세요.</p>
        <div class="tile-grid" style="--cols:4;">
          ${Array.from({ length: 16 }, (_, i) => {
            const light = i === odd ? 62 : 54;
            return `<button class="tile-button" type="button" data-odd="${i === odd}" style="background:hsl(${hue} 70% ${light}%);"></button>`;
          }).join("")}
        </div>
      `,
      statStrip([
        { label: "남은 시간", value: `${left}초` },
        { label: "점수", value: `${score}` },
        { label: "집중", value: "색" },
      ]),
    );
    byId("app").querySelectorAll("[data-odd]").forEach((button) => {
      button.addEventListener("click", () => {
        if (button.dataset.odd === "true") score += 1;
        draw();
      });
    });
  };
  addInterval(run, () => {
    left -= 1;
    if (left <= 0) finishGame(game, { value: score });
    else {
      const first = byId("app")?.querySelector(".stat-strip strong");
      if (first) first.textContent = `${left}초`;
    }
  }, 1000);
  draw();
}

function runSlot(game) {
  const run = createRun();
  const symbols = ["🍒", "⭐", "🔔", "7"];
  const picks = [];
  const reels = [0, 1, 2].map(() => symbols[randomInt(0, symbols.length - 1)]);
  activeShell(
    game,
    `
      <h2 class="active-title">릴 멈추기</h2>
      <p class="active-subtitle">돌아가는 릴을 차례대로 멈춰 같은 그림을 노리세요.</p>
      <div class="tile-grid" style="--cols:3;">
        ${reels.map((symbol, i) => `<div class="tile-button slot-reel" data-reel="${i}">${symbol}</div>`).join("")}
      </div>
      <button class="primary-action" type="button" data-stop-reel>STOP</button>
    `,
    statStrip([
      { label: "멈춘 릴", value: "0/3" },
      { label: "보너스", value: "같은 그림" },
      { label: "타이밍", value: "진행" },
    ]),
  );
  const reelEls = byId("app").querySelectorAll("[data-reel]");
  const stat = byId("app").querySelector(".stat-strip strong");
  addInterval(run, () => {
    reels.forEach((_, i) => {
      if (picks[i]) return;
      reels[i] = symbols[randomInt(0, symbols.length - 1)];
      reelEls[i].textContent = reels[i];
    });
  }, 90);
  byId("app").querySelector("[data-stop-reel]").addEventListener("click", () => {
    const index = picks.length;
    picks.push(reels[index]);
    reelEls[index].classList.add("correct");
    stat.textContent = `${picks.length}/3`;
    if (picks.length >= 3) {
      const unique = new Set(picks).size;
      const score = unique === 1 ? 100 : unique === 2 ? 40 : 10;
      finishGame(game, { value: score, message: `${picks.join(" ")} 조합입니다.` });
    }
  });
}

function bindSponsorClicks() {
  document.querySelectorAll("[data-sponsor]").forEach((link) => {
    link.addEventListener("click", () => {
      track("ad_click", { sponsorId: link.dataset.sponsor, href: link.href });
    });
  });
}

async function copyText(text) {
  try {
    await navigator.clipboard.writeText(text);
    return;
  } catch {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand("copy");
    textarea.remove();
  }
}

function showToast(message) {
  document.querySelector(".toast")?.remove();
  const toast = document.createElement("div");
  toast.className = "toast";
  toast.textContent = message;
  document.body.appendChild(toast);
  setTimeout(() => toast.remove(), 2400);
}

if (new URLSearchParams(location.search).get("game")) {
  location.hash = `#/game/${new URLSearchParams(location.search).get("game")}`;
}

window.addEventListener("hashchange", renderRoute);
renderRoute();
