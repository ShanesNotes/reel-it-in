/* =============================================================
   REEL IT IN — Intro / title sequence concepts
   Three directions, each a self-contained timed scene composed
   on the animations.jsx engine. Broadcast spec 1920×1080.
   Reads window.RII_EPISODE (from data.jsx) so the plate stays
   in sync with the episode.
   ============================================================= */

const RII = {
  cream:'#F2EBDB', creamDeep:'#EAE0C9', card:'#F7F1E3',
  ink:'#221B12', inkSoft:'#5C5142', inkFaint:'#8A7E6B',
  gold:'#AE7A2A', goldDeep:'#855B17',
  night:'#16110A', nightDeep:'#1E160D', nightCard:'#241B10',
  nightInk:'#F0E7D2', nightGold:'#E5A93F', nightTeal:'#5FA89F',
  serif:'"Fraunces", Georgia, serif',
  sans:'"Hanken Grotesk", system-ui, sans-serif',
  mono:'"JetBrains Mono", ui-monospace, monospace',
};

const NOISE = "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='180' height='180'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E\")";

function ep() {
  return window.RII_EPISODE || { number:'001', label:'Pilot', date:'May 29, 2026' };
}

// ── shared overlays ─────────────────────────────────────────
function Grain({ opacity = 0.06, blend = 'overlay' }) {
  return <div style={{
    position:'absolute', inset:0, pointerEvents:'none', zIndex:40,
    opacity, mixBlendMode:blend, backgroundImage:NOISE,
  }} />;
}
function Vignette({ strength = 0.55 }) {
  return <div style={{
    position:'absolute', inset:0, pointerEvents:'none', zIndex:30,
    background:`radial-gradient(120% 90% at 50% 46%, transparent 38%, rgba(0,0,0,${strength}) 100%)`,
  }} />;
}

// ── the wordmark, per-word controllable ─────────────────────
// Each word lives in an overflow-hidden slot; `rise` (px) slides
// the inner glyphs up from below the slot's baseline.
function Word({ children, rise = 0, opacity = 1, color, italic, gold, extra }) {
  return (
    <span style={{
      display:'inline-block', whiteSpace:'pre', verticalAlign:'bottom', lineHeight:1, flexShrink:0,
      transform:`translateY(${rise}px)`,
      opacity,
      color: gold ? undefined : color,
      ...(italic ? {
        fontStyle:'italic', fontWeight:500,
        fontVariationSettings:'"opsz" 144, "WONK" 1',
      } : {}),
      ...extra,
    }}>{children}</span>
  );
}

function Wordmark({
  size = 200, color = RII.nightInk, goldColor = RII.nightGold,
  reel = {}, it = {}, inn = {},
}) {
  return (
    <div style={{
      fontFamily:RII.serif, fontWeight:600, fontSize:size,
      lineHeight:1, letterSpacing:'-0.02em',
      fontVariationSettings:'"opsz" 144',
      display:'flex', alignItems:'flex-end', whiteSpace:'pre',
      color,
    }}>
      <Word color={color} {...reel}>Reel</Word>
      <Word italic gold extra={{ color: goldColor }} {...it}>{' It'}</Word>
      <Word color={color} {...inn}>{' In'}</Word>
    </div>
  );
}

// ── episode plate (kicker + meta line) ──────────────────────
function Plate({ progress = 1, dark = true, y = 0 }) {
  const e = ep();
  const fg = dark ? RII.nightInk : RII.ink;
  const faint = dark ? '#8A7C5F' : RII.inkFaint;
  const accent = dark ? RII.nightGold : RII.goldDeep;
  return (
    <div style={{
      display:'flex', flexDirection:'column', alignItems:'center', gap:18,
      opacity:progress,
      transform:`translateY(${(1 - progress) * 14 + y}px)`,
    }}>
      <div style={{
        fontFamily:RII.mono, fontSize:21, letterSpacing:'0.34em',
        textTransform:'uppercase', color:accent, whiteSpace:'nowrap',
      }}>A Father–Son Conversation About A.I.</div>
      <div style={{
        display:'flex', alignItems:'center', gap:18, whiteSpace:'nowrap',
        fontFamily:RII.mono, fontSize:24, letterSpacing:'0.16em',
        textTransform:'uppercase', color:fg, fontVariantNumeric:'tabular-nums',
      }}>
        <span>Episode {e.number}</span>
        <span style={{ width:6, height:6, borderRadius:'50%', background:accent }} />
        <span>{e.label}</span>
        <span style={{ width:6, height:6, borderRadius:'50%', background:accent }} />
        <span style={{ color:faint }}>{String(e.date).toUpperCase()}</span>
      </div>
    </div>
  );
}

// helper: masked-rise px for a word over [s,e]
function risePx(t, s, e, ease = Easing.easeOutCubic, dist = 52) {
  return interpolate([s, e], [dist, 0], ease)(t);
}
function fadeIn(t, s, e) {
  return interpolate([s, e], [0, 1], Easing.easeOutCubic)(t);
}

/* ═══════════════════════════════════════════════════════════
   CONCEPT A — "THE LINE"  (hero · on-air dark)
   A gold waterline draws across; the words rise out of it,
   the gold italic "It" surfacing last — the catch reeled in.
   ═══════════════════════════════════════════════════════════ */
function LineIntro() {
  const t = useTime();

  const lineScale = interpolate([0.15, 1.05], [0, 1], Easing.easeOutExpo)(t);
  const lineBright = interpolate([1.9, 2.5, 3.0], [0.5, 1, 0.7], Easing.easeInOutQuad)(t);
  const lineShrink = interpolate([2.8, 3.4], [1, 0.26], Easing.easeInOutCubic)(t);
  const lineFade   = interpolate([2.9, 3.5], [1, 0], Easing.easeInOutQuad)(t);

  const reel = risePx(t, 0.95, 1.6);
  const inn  = risePx(t, 1.15, 1.8);
  const it   = risePx(t, 2.0, 2.85, Easing.easeOutBack, 64);
  const itScale = interpolate([2.0, 2.85, 3.05], [1.06, 1.06, 1], Easing.easeOutCubic)(t);
  const reelO = fadeIn(t, 0.95, 1.35);
  const innO  = fadeIn(t, 1.15, 1.55);
  const itO   = fadeIn(t, 2.0, 2.4);

  const plate = interpolate([3.4, 4.3], [0, 1], Easing.easeOutCubic)(t);
  const out   = interpolate([7.1, 7.9], [1, 0], Easing.easeInOutQuad)(t);

  const lineW = 860;

  return (
    <div style={{ position:'absolute', inset:0, background:RII.night, opacity:out }}>
      <div style={{
        position:'absolute', left:0, right:0, top:'50%',
        transform:'translateY(-50%)',
        display:'flex', flexDirection:'column', alignItems:'center', gap:64,
      }}>
        {/* wordmark + waterline */}
        <div style={{ position:'relative', display:'flex', justifyContent:'center' }}>
          <Wordmark
            size={208}
            reel={{ rise: reel, opacity: reelO }}
            inn={{ rise: inn, opacity: innO }}
            it={{ rise: it, opacity: itO, extra:{ color:RII.nightGold, transform:`translateY(${it}px) scale(${itScale})`, transformOrigin:'center bottom' } }}
          />
          <div style={{
            position:'absolute', bottom:-26, left:'50%',
            width:lineW, height:2.5,
            transform:`translateX(-50%) scaleX(${lineScale * lineShrink})`,
            background:`linear-gradient(90deg, transparent, ${RII.nightGold} 12%, ${RII.nightGold} 88%, transparent)`,
            opacity:lineFade * lineBright,
            boxShadow:`0 0 14px rgba(229,169,63,${0.35 * lineFade})`,
          }} />
        </div>
        <Plate progress={plate} dark />
      </div>
      <Vignette strength={0.6} />
      <Grain opacity={0.07} blend="overlay" />
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════
   CONCEPT B — "THE LEADER"  (countdown · on-air dark)
   A film-leader countdown in Fraunces numerals with a gold
   sweep hand; resolves into the wordmark. Doubles as Standby.
   ═══════════════════════════════════════════════════════════ */
function SweepRing({ t }) {
  // active during 0–3s; one full sweep per second
  const within = t % 1;
  const angle = within * 360;
  const ringFade = interpolate([0, 0.4, 3.0, 3.4], [0, 1, 1, 0], Easing.easeInOutQuad)(t);
  const R = 300;
  return (
    <svg width="760" height="760" viewBox="-380 -380 760 760" style={{
      position:'absolute', left:'50%', top:'50%',
      transform:'translate(-50%,-50%)', opacity:ringFade, zIndex:5,
    }}>
      {/* crosshair */}
      <line x1="-360" y1="0" x2="360" y2="0" stroke={RII.nightTeal} strokeWidth="1" opacity="0.32" />
      <line x1="0" y1="-360" x2="0" y2="360" stroke={RII.nightTeal} strokeWidth="1" opacity="0.32" />
      <circle r={R} fill="none" stroke="rgba(240,231,210,0.18)" strokeWidth="1.5" />
      <circle r={R - 22} fill="none" stroke="rgba(240,231,210,0.10)" strokeWidth="1" />
      {/* swept wedge */}
      <path
        d={describeWedge(0, R, angle)}
        fill="rgba(229,169,63,0.10)"
      />
      {/* sweep hand */}
      <g transform={`rotate(${angle - 90})`}>
        <line x1="0" y1="0" x2={R} y2="0" stroke={RII.nightGold} strokeWidth="2.5" />
        <circle cx={R} cy="0" r="4.5" fill={RII.nightGold} />
      </g>
      <circle r="5" fill={RII.nightGold} />
    </svg>
  );
}
function describeWedge(startDeg, r, endDeg) {
  const a0 = (startDeg - 90) * Math.PI / 180;
  const a1 = (endDeg - 90) * Math.PI / 180;
  const x0 = r * Math.cos(a0), y0 = r * Math.sin(a0);
  const x1 = r * Math.cos(a1), y1 = r * Math.sin(a1);
  const large = (endDeg - startDeg) > 180 ? 1 : 0;
  return `M0 0 L${x0} ${y0} A${r} ${r} 0 ${large} 1 ${x1} ${y1} Z`;
}

function LeaderNumeral({ label }) {
  const { progress } = useSprite();
  // each numeral: quick scale-settle in, hold, quick out
  const op = interpolate([0, 0.14, 0.82, 1], [0, 1, 1, 0], Easing.easeInOutQuad)(progress);
  const sc = interpolate([0, 0.18], [1.18, 1], Easing.easeOutBack)(progress);
  return (
    <div style={{
      position:'absolute', left:'50%', top:'50%',
      transform:`translate(-50%,-50%) scale(${sc})`,
      opacity:op, zIndex:8,
      fontFamily:RII.serif, fontStyle:'italic', fontWeight:500,
      fontSize:300, lineHeight:1, color:RII.nightGold,
      fontVariationSettings:'"opsz" 144',
    }}>{label}</div>
  );
}

function LeaderIntro() {
  const t = useTime();
  const flash = interpolate([3.0, 3.12, 3.3], [0, 0.85, 0], Easing.easeInOutQuad)(t);

  const reel = risePx(t, 3.45, 4.05);
  const inn  = risePx(t, 3.6, 4.2);
  const it   = risePx(t, 3.8, 4.5, Easing.easeOutBack, 64);
  const reelO = fadeIn(t, 3.45, 3.85);
  const innO  = fadeIn(t, 3.6, 4.0);
  const itO   = fadeIn(t, 3.8, 4.2);
  const markScale = interpolate([3.4, 4.4], [0.92, 1], Easing.easeOutCubic)(t);

  const plate = interpolate([4.6, 5.4], [0, 1], Easing.easeOutCubic)(t);
  const out   = interpolate([6.3, 6.95], [1, 0], Easing.easeInOutQuad)(t);

  return (
    <div style={{ position:'absolute', inset:0, background:RII.night, opacity:out }}>
      <Sprite start={0} end={3.05}><SweepRingWrap /></Sprite>
      <Sprite start={0} end={1.0}><LeaderNumeral label="III" /></Sprite>
      <Sprite start={1.0} end={2.0}><LeaderNumeral label="II" /></Sprite>
      <Sprite start={2.0} end={3.0}><LeaderNumeral label="I" /></Sprite>

      {/* white flash on resolve */}
      <div style={{ position:'absolute', inset:0, background:RII.nightInk, opacity:flash, zIndex:20 }} />

      {/* wordmark + plate */}
      <Sprite start={3.3} end={Infinity}>
        <div style={{
          position:'absolute', left:0, right:0, top:'50%',
          transform:`translateY(-50%)`,
          display:'flex', flexDirection:'column', alignItems:'center', gap:60,
        }}>
          <div style={{ transform:`scale(${markScale})` }}>
            <Wordmark size={196} reel={{ rise:reel, opacity:reelO }} inn={{ rise:inn, opacity:innO }} it={{ rise:it, opacity:itO }} />
          </div>
          <Plate progress={plate} dark />
        </div>
      </Sprite>

      <Vignette strength={0.5} />
      <Grain opacity={0.07} blend="overlay" />
    </div>
  );
}
function SweepRingWrap() {
  const t = useTime();
  return <SweepRing t={t} />;
}

/* ═══════════════════════════════════════════════════════════
   CONCEPT C — "LETTERPRESS"  (warm paper)
   The wordmark presses into cream stock; grain blooms, a gold
   rule draws beneath, the plate settles. Magazine masthead.
   ═══════════════════════════════════════════════════════════ */
function LetterpressIntro() {
  const t = useTime();

  const press   = interpolate([0.2, 0.95, 1.2], [1.06, 0.995, 1], Easing.easeOutExpo)(t);
  const markOp  = interpolate([0.2, 0.7], [0, 1], Easing.easeOutCubic)(t);
  const blur    = interpolate([0.2, 0.9], [7, 0], Easing.easeOutCubic)(t);
  const tracking= interpolate([0.2, 1.0], [0.02, -0.02], Easing.easeOutCubic)(t);
  const grainOp = interpolate([0.6, 1.6], [0, 0.05], Easing.easeOutCubic)(t);

  const rule    = interpolate([1.2, 2.0], [0, 1], Easing.easeInOutCubic)(t);
  const kicker  = interpolate([1.5, 2.3], [0, 1], Easing.easeOutCubic)(t);
  const plate   = interpolate([1.8, 2.6], [0, 1], Easing.easeOutCubic)(t);
  const out     = interpolate([5.6, 6.4], [1, 0], Easing.easeInOutQuad)(t);

  const e = ep();

  return (
    <div style={{ position:'absolute', inset:0, background:RII.cream, opacity:out }}>
      <div style={{
        position:'absolute', left:0, right:0, top:'50%',
        transform:'translateY(-50%)',
        display:'flex', flexDirection:'column', alignItems:'center', gap:30,
      }}>
        <div style={{
          fontFamily:RII.mono, fontSize:20, letterSpacing:'0.34em',
          textTransform:'uppercase', color:RII.goldDeep, whiteSpace:'nowrap',
          opacity:kicker, transform:`translateY(${(1 - kicker) * 10}px)`,
        }}>A Father–Son Conversation About A.I.</div>

        <div style={{
          fontFamily:RII.serif, fontWeight:600, fontSize:210, lineHeight:1,
          letterSpacing:`${tracking}em`, fontVariationSettings:'"opsz" 144',
          color:RII.ink, opacity:markOp, filter:`blur(${blur}px)`,
          transform:`scale(${press})`, display:'flex', whiteSpace:'pre',
        }}>
          Reel
          <span style={{
            fontStyle:'italic', fontWeight:500, color:RII.gold,
            fontVariationSettings:'"opsz" 144, "WONK" 1',
          }}>{' It'}</span>
          {' In'}
        </div>

        <div style={{
          width:520, height:2,
          transform:`scaleX(${rule})`,
          background:`linear-gradient(90deg, transparent, ${RII.gold}, transparent)`,
        }} />

        <div style={{
          display:'flex', alignItems:'center', gap:18,
          fontFamily:RII.mono, fontSize:23, letterSpacing:'0.16em',
          textTransform:'uppercase', color:RII.inkSoft, fontVariantNumeric:'tabular-nums',
          opacity:plate, transform:`translateY(${(1 - plate) * 10}px)`, whiteSpace:'nowrap',
        }}>
          <span>Episode {e.number}</span>
          <span style={{ width:6, height:6, borderRadius:'50%', background:RII.gold }} />
          <span>{e.label}</span>
          <span style={{ width:6, height:6, borderRadius:'50%', background:RII.gold }} />
          <span style={{ color:RII.inkFaint }}>{String(e.date).toUpperCase()}</span>
        </div>
      </div>
      <Grain opacity={grainOp} blend="multiply" />
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════
   MASTER — "THE REEL"  (countdown → silence → the line)
   The two chosen beats stitched into one sequence, paced for a
   score: cello crescendo over the count, a held silence at the
   cut, then a mechanical reel as the line draws and the catch
   ("It") surfaces. Beat times live in MASTER_CUES below.
   ═══════════════════════════════════════════════════════════ */
function MasterIntro() {
  const t = useTime();

  // ---- PART 1 · countdown (0–3.0) ----
  const flash = interpolate([3.0, 3.14, 3.34], [0, 0.9, 0], Easing.easeInOutQuad)(t);

  // ---- PART 2 · the line (after the silence beat ~3.3–3.75) ----
  const lineScale  = interpolate([3.75, 4.6], [0, 1], Easing.easeOutExpo)(t);
  const lineBright = interpolate([5.2, 5.9, 6.4], [0.5, 1, 0.7], Easing.easeInOutQuad)(t);
  const lineShrink = interpolate([6.4, 7.0], [1, 0.26], Easing.easeInOutCubic)(t);
  const lineFade   = interpolate([6.5, 7.1], [1, 0], Easing.easeInOutQuad)(t);

  const reel  = risePx(t, 4.45, 5.1);
  const inn   = risePx(t, 4.6, 5.25);
  const it    = risePx(t, 5.5, 6.35, Easing.easeOutBack, 64);
  const itScale = interpolate([5.5, 6.35, 6.55], [1.06, 1.06, 1], Easing.easeOutCubic)(t);
  const reelO = fadeIn(t, 4.45, 4.85);
  const innO  = fadeIn(t, 4.6, 5.0);
  const itO   = fadeIn(t, 5.5, 5.9);

  const plate = interpolate([6.9, 7.8], [0, 1], Easing.easeOutCubic)(t);
  const out   = interpolate([8.7, 9.4], [1, 0], Easing.easeInOutQuad)(t);

  const lineW = 860;

  return (
    <div style={{ position:'absolute', inset:0, background:RII.night, opacity:out }}>
      {/* countdown */}
      <Sprite start={0} end={3.05}><SweepRingWrap /></Sprite>
      <Sprite start={0} end={1.0}><LeaderNumeral label="III" /></Sprite>
      <Sprite start={1.0} end={2.0}><LeaderNumeral label="II" /></Sprite>
      <Sprite start={2.0} end={3.0}><LeaderNumeral label="I" /></Sprite>

      {/* resolve flash */}
      <div style={{ position:'absolute', inset:0, background:RII.nightInk, opacity:flash, zIndex:20 }} />

      {/* the line + wordmark + plate */}
      <Sprite start={3.3} end={Infinity}>
        <div style={{
          position:'absolute', left:0, right:0, top:'50%',
          transform:'translateY(-50%)',
          display:'flex', flexDirection:'column', alignItems:'center', gap:64,
        }}>
          <div style={{ position:'relative', display:'flex', justifyContent:'center' }}>
            <Wordmark
              size={208}
              reel={{ rise: reel, opacity: reelO }}
              inn={{ rise: inn, opacity: innO }}
              it={{ rise: it, opacity: itO, extra:{ color:RII.nightGold, transform:`translateY(${it}px) scale(${itScale})`, transformOrigin:'center bottom' } }}
            />
            <div style={{
              position:'absolute', bottom:-26, left:'50%',
              width:lineW, height:2.5,
              transform:`translateX(-50%) scaleX(${lineScale * lineShrink})`,
              background:`linear-gradient(90deg, transparent, ${RII.nightGold} 12%, ${RII.nightGold} 88%, transparent)`,
              opacity:lineFade * lineBright,
              boxShadow:`0 0 14px rgba(229,169,63,${0.35 * lineFade})`,
            }} />
          </div>
          <Plate progress={plate} dark />
        </div>
      </Sprite>

      <Vignette strength={0.58} />
      <Grain opacity={0.07} blend="overlay" />
    </div>
  );
}

// Cue sheet for the master sequence — handoff spec for scoring.
// kind: 'build' (crescendo) · 'silence' · 'hit' (mechanical) · 'resolve'
const MASTER_CUES = [
  { t:0.0,  label:'III',                 audio:'Cello enters — low, single sustained note', kind:'build' },
  { t:1.0,  label:'II',                  audio:'Second note, a step up — bow pressure grows', kind:'build' },
  { t:2.0,  label:'I',                   audio:'Third note — crescendo peaks toward the cut', kind:'build' },
  { t:3.0,  label:'Flash / cut',         audio:'Sharp swell, then hard stop on the white flash', kind:'hit' },
  { t:3.3,  label:'Silence',             audio:'Held silence — ~0.4s of black, no sound', kind:'silence' },
  { t:3.75, label:'Waterline draws',     audio:'Mechanical reel-out — a taut line zipping across', kind:'hit' },
  { t:4.45, label:'“Reel” · “In” rise',  audio:'Small mechanical settle clicks as words seat', kind:'hit' },
  { t:5.5,  label:'“It” surfaces',       audio:'The catch — a single firm mechanical thunk', kind:'hit' },
  { t:6.5,  label:'Line dissolves',      audio:'Mechanism settles; a warm low cello returns', kind:'resolve' },
  { t:6.9,  label:'Episode plate',       audio:'Resolve — sustain blooms and fades under the title', kind:'resolve' },
  { t:8.7,  label:'Out',                 audio:'Tail fades to silence', kind:'resolve' },
];

Object.assign(window, {
  RII, LineIntro, LeaderIntro, LetterpressIntro, MasterIntro, MASTER_CUES,
});
