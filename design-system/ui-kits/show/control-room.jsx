/* =============================================================
   REEL IT IN — Operator Control Dashboard · app
   Single-operator "control room" for running a recording.
   Reads window.RII_* (data.jsx). Dark on-air theme.

   Keys:  Space/R = record toggle · S = standby · ←/→ = move spark
          C = cover current · Enter = next uncovered · ? = (future) help
   ============================================================= */
const { useState, useEffect, useRef, useCallback, useMemo } = React;

const SPARKS  = window.RII_SPARKS;
const EPISODE = window.RII_EPISODE;

const mmss = (s) => {
  s = Math.max(0, Math.floor(s));
  return String(Math.floor(s/60)).padStart(2,"0") + ":" + String(s%60).padStart(2,"0");
};

/* ---- small presentational pieces ---- */
function Call({ hosts }) {
  return (
    <div className="call">
      <span className="who"><span className="pres"></span>{hosts.you}</span>
      <span className="who"><span className="pres"></span>{hosts.dad}</span>
      <span className="tag">On the call · Zoom</span>
    </div>
  );
}

function ActRow({ act, active, done, onClick }) {
  return (
    <div className={"act-row" + (active ? " active" : "") + (done ? " done" : "")} onClick={onClick}>
      <span className="rn">{act.act}.</span>
      <span>
        <span className="at">{act.title}</span>
        <span className="an">{act.note}</span>
      </span>
      <span className="bud">{act.budgetMin}m</span>
    </div>
  );
}

function SparkRow({ id, i, active, covered, budget, onJump, onCover }) {
  const s = SPARKS[id];
  return (
    <div className={"spark-row" + (active ? " active" : "") + (covered ? " covered" : "")} onClick={() => onJump(i)}>
      <span className="mk" onClick={(e)=>{e.stopPropagation(); onCover(i);}}>{covered ? "✓" : (i+1)}</span>
      <span style={{minWidth:0}}>
        <span className="sl-tag">{s.tag}</span>
        <span className="sl-prompt">{s.prompt}</span>
      </span>
      <span className="sl-time">{budget}</span>
    </div>
  );
}

function App() {
  const featured = useMemo(() => EPISODE.featuredSparks.filter(id => SPARKS[id]), []);
  const sparkBudgetSec = useMemo(() => {
    const actIII = EPISODE.rundown.find(r => r.kind === "sparks");
    const total = (actIII ? actIII.budgetMin : 18) * 60;
    return Math.round(total / featured.length);
  }, [featured]);

  const [state, setState]   = useState("standby");   // standby | recording | wrapped
  const [total, setTotal]   = useState(0);            // total elapsed seconds
  const [segStart, setSegStart] = useState(0);        // total-seconds at which current segment began
  const [index, setIndex]   = useState(0);            // current featured-spark index
  const [covered, setCovered] = useState(new Set());

  const stateRef = useRef(state); stateRef.current = state;
  const tickRef = useRef(null);

  /* master clock — only advances while recording */
  useEffect(() => {
    if (state !== "recording") return;
    const id = setInterval(() => setTotal(t => t + 1), 1000);
    tickRef.current = id;
    return () => clearInterval(id);
  }, [state]);

  const segElapsed = total - segStart;
  const segRatio = Math.min(1.4, segElapsed / sparkBudgetSec);
  const segPhase = segElapsed > sparkBudgetSec ? "over" : (segElapsed > sparkBudgetSec - 30 ? "warn" : "");

  const cur = SPARKS[featured[index]];
  const nextIdx = index + 1;
  const atEnd = nextIdx >= featured.length;
  const nextSpark = atEnd ? null : SPARKS[featured[nextIdx]];

  // live ref of total so move()/cover can stamp segStart without re-binding
  const totalRef = useRef(total); totalRef.current = total;

  const move = useCallback((d) => {
    setIndex(i => {
      const n = Math.min(featured.length - 1, Math.max(0, i + d));
      if (n !== i) setSegStart(stateRef.current === "recording" ? totalRef.current : 0);
      return n;
    });
  }, [featured.length]);

  const toggleCover = useCallback((i) => {
    setCovered(prev => { const n = new Set(prev); n.has(i) ? n.delete(i) : n.add(i); return n; });
  }, []);
  const coverCurrent = useCallback(() => toggleCover(index), [index, toggleCover]);

  const nextUncovered = useCallback(() => {
    for (let k = index + 1; k < featured.length; k++) if (!covered.has(k)) { move(k - index); return; }
    move(1);
  }, [index, featured.length, covered, move]);

  const toggleRec = useCallback(() => {
    setState(s => s === "recording" ? "wrapped" : "recording");
    if (stateRef.current !== "recording") setSegStart(totalRef.current);
  }, []);
  const toStandby = useCallback(() => { setState("standby"); setTotal(0); setSegStart(0); setCovered(new Set()); setIndex(0); }, []);

  /* keyboard */
  useEffect(() => {
    const onKey = (e) => {
      if (e.key === " " || e.key === "r" || e.key === "R") { e.preventDefault(); toggleRec(); }
      else if (e.key === "s" || e.key === "S") toStandby();
      else if (e.key === "ArrowRight") { e.preventDefault(); move(1); }
      else if (e.key === "ArrowLeft")  { e.preventDefault(); move(-1); }
      else if (e.key === "c" || e.key === "C") coverCurrent();
      else if (e.key === "Enter") { e.preventDefault(); nextUncovered(); }
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [toggleRec, toStandby, move, coverCurrent, nextUncovered]);

  /* replay swap animation when the current spark changes */
  const nowRef = useRef(null);
  useEffect(() => {
    const el = nowRef.current; if (!el) return;
    el.classList.remove("now-anim"); void el.offsetWidth; el.classList.add("now-anim");
  }, [index]);

  const stateLabel = { standby:"Standby", recording:"● Rec", wrapped:"Wrapped" }[state];
  const coveredCount = covered.size;

  return (
    <div id="dash">
      <div className="dash-top">
        <div className="left">
          <button className={"recstate " + state} onClick={toggleRec} title="Space / R">
            <span className="led"></span>{stateLabel}
          </button>
          <span className="ep-id">Reel It In · EP {EPISODE.number} · <b>{EPISODE.label}</b></span>
        </div>
        <div className="total-clock">{mmss(total)}<span className="of">/ {EPISODE.targetMin}:00 target</span></div>
        <div className="right"><Call hosts={EPISODE.hosts} /></div>
      </div>

      <div className="dash-body">
        {/* ---- rundown spine ---- */}
        <aside className="rundown">
          <h2>Run of show</h2>
          {EPISODE.rundown.map((act, ai) => (
            <div className="act" key={act.act}>
              <ActRow act={act} active={act.kind === "sparks"} done={false} onClick={() => {}} />
              {act.kind === "sparks" && (
                <div className="spark-list">
                  {featured.map((id, i) => (
                    <SparkRow key={id} id={id} i={i} active={i === index} covered={covered.has(i)}
                      budget={mmss(sparkBudgetSec)} onJump={(n)=>move(n-index)} onCover={toggleCover} />
                  ))}
                </div>
              )}
            </div>
          ))}
          <div className="coverage">
            <span className="c-label">Covered</span>
            <div className="cov-bar"><i style={{width:(coveredCount/featured.length*100)+"%"}}></i></div>
            <span className="c-num"><b>{coveredCount}</b> / {featured.length}</span>
          </div>
        </aside>

        {/* ---- NOW panel ---- */}
        <main className="now">
          <div className="now-head">
            <span className="now-kicker">Now · spark {index+1} of {featured.length}</span>
            <span className="now-kicker">{covered.has(index) ? "✓ covered" : "live"}</span>
          </div>
          <div ref={nowRef}>
            <div className="now-tag">{cur.tag}</div>
            <p className="now-prompt">{cur.prompt}</p>
            <p className="now-aside">{cur.aside}</p>
          </div>

          <div className="now-spacer"></div>

          <div className={"seg " + segPhase}>
            <span className="seg-label">On this spark</span>
            <span className="seg-time">{mmss(segElapsed)}<span className="budget">/ {mmss(sparkBudgetSec)}</span></span>
            <div className="seg-track"><i style={{width:Math.min(100, segRatio*100/1.0)+"%"}}></i></div>
          </div>

          <div className={"next" + (atEnd ? " end" : "")}>
            <span className="nx-label">Next</span>
            <div className="nx-body">
              {atEnd ? (
                <div className="nx-prompt">Last spark — head into the wrap.</div>
              ) : (
                <React.Fragment>
                  <div className="nx-tag">{nextSpark.tag}</div>
                  <div className="nx-prompt">{nextSpark.prompt}</div>
                </React.Fragment>
              )}
            </div>
          </div>

          <div className="controls">
            <button className={"ctl" + (covered.has(index) ? " on" : "")} onClick={coverCurrent}>
              {covered.has(index) ? "✓ Covered" : "Mark covered"} <kbd>C</kbd>
            </button>
            <button className="ctl" onClick={() => move(-1)}>‹ Prev <kbd>←</kbd></button>
            <button className="ctl" onClick={() => move(1)}>Next › <kbd>→</kbd></button>
            <button className="ctl primary" onClick={nextUncovered}>Next uncovered <kbd>↵</kbd></button>
            <span className="hint">Space rec · S standby</span>
          </div>
        </main>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
