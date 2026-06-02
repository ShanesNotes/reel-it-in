/* =============================================================
   REEL IT IN — Intro player shell
   Concept switcher + a Stage per direction. Each concept owns
   its duration + persisted playhead.
   ============================================================= */

const CONCEPTS = [
  { id:'master', name:'Full Sequence', dur:9.6, bg:RII.night,
    blurb:'The chosen cut: the Leader countdown crescendos, cuts to a held silence, then the waterline reels the wordmark in — the gold “It” surfacing last. Scored for cello → silence → mechanical resolve. Cue sheet below.' },
  { id:'line', name:'The Line', dur:8.2, bg:RII.night,
    blurb:'A gold waterline draws across; the words rise out of it — the italic “It” surfacing last, the catch reeled in. On-air dark. The hero.' },
  { id:'leader', name:'The Leader', dur:7.2, bg:RII.night,
    blurb:'A film-leader countdown — Fraunces numerals III · II · I with a gold sweep hand — resolving into the wordmark. Doubles as your Standby countdown.' },
  { id:'letterpress', name:'Letterpress', dur:6.6, bg:RII.cream,
    blurb:'The wordmark presses into cream stock; grain blooms and a gold rule draws beneath. Warm, magazine-masthead. The quiet one.' },
];

const CUE_COLORS = {
  build:   '#5FA89F',  // teal — crescendo
  silence: '#6E6354',  // faint — the held silence
  hit:     '#E5A93F',  // gold — mechanical sync points
  resolve: '#C5B594',  // warm — the resolve
};

// Live cue sheet for the master sequence. Reads the Stage's persisted
// playhead from localStorage (decoupled — no per-frame App re-render).
function CueSheet({ persistKey, duration }) {
  const headRef = React.useRef(null);
  const dotRefs = React.useRef([]);
  const [open, setOpen] = React.useState(false);

  React.useEffect(() => {
    let raf;
    const tick = () => {
      let t = 0;
      try { t = parseFloat(localStorage.getItem(persistKey + ':t') || '0') || 0; } catch {}
      const pct = Math.max(0, Math.min(1, t / duration)) * 100;
      if (headRef.current) headRef.current.style.left = pct + '%';
      MASTER_CUES.forEach((c, i) => {
        const el = dotRefs.current[i];
        if (!el) return;
        const active = t >= c.t - 0.02;
        el.style.opacity = active ? '1' : '0.4';
        el.style.transform = active ? 'scale(1.5)' : 'scale(1)';
      });
      raf = requestAnimationFrame(tick);
    };
    tick();
    return () => cancelAnimationFrame(raf);
  }, [persistKey, duration]);

  return (
    <div style={{ flexShrink:0, padding:'12px 24px 14px', background:'#0d0b07', borderTop:'1px solid rgba(240,231,210,0.08)' }}>
      <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:10, gap:16 }}>
        <button
          onClick={() => setOpen(o => !o)}
          style={{
            display:'flex', alignItems:'center', gap:9, cursor:'pointer',
            background:'transparent', border:'none', padding:0,
            fontFamily:RII.mono, fontSize:11, letterSpacing:'0.24em',
            textTransform:'uppercase', color:RII.nightGold,
          }}
        >
          <span style={{ display:'inline-block', transform:open?'rotate(90deg)':'rotate(0deg)', fontSize:9 }}>▶</span>
          Score Cue Sheet · 9.6s {open ? '' : '· tap to expand'}
        </button>
        <div style={{ display:'flex', gap:16, fontFamily:RII.mono, fontSize:10, letterSpacing:'0.1em', textTransform:'uppercase', color:'#8A7C5F' }}>
          <span style={{ color:CUE_COLORS.build }}>● Crescendo</span>
          <span style={{ color:CUE_COLORS.silence }}>● Silence</span>
          <span style={{ color:CUE_COLORS.hit }}>● Mech. hit</span>
          <span style={{ color:CUE_COLORS.resolve }}>● Resolve</span>
        </div>
      </div>

      {/* timeline track — always visible */}
      <div style={{ position:'relative', height:22 }}>
        <div style={{ position:'absolute', left:0, right:0, top:11, height:1, background:'rgba(240,231,210,0.14)' }} />
        <div ref={headRef} style={{ position:'absolute', top:1, left:'0%', width:1.5, height:20, background:RII.nightInk, boxShadow:'0 0 6px rgba(240,231,210,0.6)' }} />
        {MASTER_CUES.map((c, i) => (
          <div key={i} style={{ position:'absolute', left:(c.t / 9.6 * 100) + '%', top:11, transform:'translate(-50%,-50%)' }}>
            <div ref={el => dotRefs.current[i] = el} style={{
              width:7, height:7, borderRadius:'50%', background:CUE_COLORS[c.kind], opacity:0.4,
            }} />
          </div>
        ))}
      </div>

      {/* detailed legend — collapsible */}
      {open && (
        <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fit, minmax(230px, 1fr))', gap:'7px 22px', marginTop:14 }}>
          {MASTER_CUES.map((c, i) => (
            <div key={i} style={{ display:'flex', gap:9, alignItems:'baseline' }}>
              <span style={{ fontFamily:RII.mono, fontSize:11, color:CUE_COLORS[c.kind], fontVariantNumeric:'tabular-nums', width:34, flexShrink:0 }}>
                {c.t.toFixed(1)}s
              </span>
              <span style={{ fontFamily:RII.sans, fontSize:12, color:RII.nightInk, fontWeight:600, width:120, flexShrink:0 }}>{c.label}</span>
              <span style={{ fontFamily:RII.sans, fontSize:12, color:'#9C8E72', lineHeight:1.4 }}>{c.audio}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function DebugSeek() {
  const { setTime, setPlaying } = useTimeline();
  React.useEffect(() => {
    window.__seek = (t) => { setPlaying(false); setTime(t); };
    window.__play = () => setPlaying(true);
  }, [setTime, setPlaying]);
  return null;
}

function App() {
  const [sel, setSel] = React.useState(() => {
    try { return localStorage.getItem('rii-intro:concept') || 'master'; } catch { return 'master'; }
  });
  React.useEffect(() => {
    try { localStorage.setItem('rii-intro:concept', sel); } catch {}
  }, [sel]);

  const c = CONCEPTS.find(x => x.id === sel) || CONCEPTS[0];

  const Scene = sel === 'master' ? MasterIntro
              : sel === 'line' ? LineIntro
              : sel === 'leader' ? LeaderIntro
              : LetterpressIntro;

  return (
    <div style={{ position:'absolute', inset:0, display:'flex', flexDirection:'column', background:'#0a0a0a' }}>
      {/* top bar */}
      <div style={{
        flexShrink:0, padding:'16px 24px 14px',
        borderBottom:'1px solid rgba(240,231,210,0.10)',
        display:'flex', flexDirection:'column', gap:12,
        background:'#0d0b07',
      }}>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', gap:16 }}>
          <div style={{
            fontFamily:RII.mono, fontSize:12, letterSpacing:'0.28em',
            textTransform:'uppercase', color:RII.nightGold,
          }}>Reel It In · Intro Sequence</div>
          <div style={{
            fontFamily:RII.mono, fontSize:11, letterSpacing:'0.14em',
            textTransform:'uppercase', color:'#8A7C5F',
          }}>1920 × 1080 · Screen-capture / OBS-ready</div>
        </div>
        <div style={{ display:'flex', alignItems:'center', gap:18, flexWrap:'wrap' }}>
          <div style={{ display:'flex', gap:9 }}>
            {CONCEPTS.map(x => {
              const on = x.id === sel;
              return (
                <button
                  key={x.id}
                  onClick={() => setSel(x.id)}
                  style={{
                    fontFamily:RII.mono, fontSize:12, letterSpacing:'0.14em',
                    textTransform:'uppercase', cursor:'pointer',
                    padding:'9px 16px', borderRadius:40,
                    border:`1px solid ${on ? RII.nightGold : 'rgba(240,231,210,0.16)'}`,
                    background: on ? RII.nightGold : 'transparent',
                    color: on ? '#16110A' : '#C5B594',
                  }}
                >{x.name}</button>
              );
            })}
          </div>
          <div style={{
            flex:1, minWidth:280, fontFamily:RII.sans, fontSize:13.5,
            lineHeight:1.5, color:'#C5B594', maxWidth:760,
          }}>{c.blurb}</div>
        </div>
      </div>

      {/* stage */}
      <div style={{ position:'relative', flex:1, minHeight:0 }}>
        <Stage
          key={sel}
          width={1920}
          height={1080}
          duration={c.dur}
          background={c.bg}
          persistKey={`rii-intro-${sel}`}
        >
          <Scene />
          <DebugSeek />
        </Stage>
      </div>

      {sel === 'master' && <CueSheet persistKey="rii-intro-master" duration={9.6} />}
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
