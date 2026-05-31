/* =============================================================
   REEL IT IN — Show UI Kit · App
   Composes the show document and wires the live production tools:
   theme flip, on-air clock, focus deck, covered tracking, wildcard.
   Episode data comes from data.jsx (window.RII_*).
   ============================================================= */

const SPARK_LIBRARY = window.RII_SPARKS;
const EPISODE = window.RII_EPISODE;
const ARCHIVE = window.RII_ARCHIVE;

function App() {
  const featured = EPISODE.featuredSparks.filter(id => SPARK_LIBRARY[id]);
  const [live, setLive] = useState(false);
  const [open, setOpen] = useState(false);
  const [index, setIndex] = useState(0);
  const [wild, setWild] = useState(null);      // spark id when wildcard, else null
  const [covered, setCovered] = useState(new Set());
  const [scale, setScale] = useState(1);
  const [clock, setClock] = useState("00:00");

  const liveRef = useRef(live), openRef = useRef(open);
  liveRef.current = live; openRef.current = open;

  /* on-air clock */
  useEffect(() => {
    if (!live) { setClock("00:00"); return; }
    const start = Date.now();
    const id = setInterval(() => {
      const t = Math.floor((Date.now() - start) / 1000);
      setClock(String(Math.floor(t/60)).padStart(2,"0") + ":" + String(t%60).padStart(2,"0"));
    }, 1000);
    return () => clearInterval(id);
  }, [live]);

  const currentSpark = wild !== null ? SPARK_LIBRARY[wild] : SPARK_LIBRARY[featured[index]];

  const openFocus = useCallback((i) => { setIndex(i); setWild(null); setOpen(true); }, []);
  const closeFocus = useCallback(() => setOpen(false), []);
  const move = useCallback((d) => { setWild(null); setIndex(i => (i + d + featured.length) % featured.length); }, [featured.length]);
  const toggleCoverId = useCallback((id) => {
    setCovered(prev => { const n = new Set(prev); n.has(id) ? n.delete(id) : n.add(id); return n; });
  }, []);
  const coverCurrent = useCallback(() => { if (wild === null) toggleCoverId(featured[index]); }, [wild, index, featured, toggleCoverId]);
  const wildcard = useCallback(() => {
    const keys = Object.keys(SPARK_LIBRARY);
    let pick; do { pick = keys[Math.floor(Math.random()*keys.length)]; } while (keys.length > 1 && pick === (wild ?? featured[index]));
    setWild(pick); setOpen(true);
  }, [wild, index, featured]);
  const bumpScale = useCallback((d) => setScale(s => Math.min(1.8, Math.max(.7, +(s + d).toFixed(2)))), []);

  const toggleLive = useCallback(() => {
    setLive(v => {
      const next = !v;
      if (next) setTimeout(() => document.querySelector(".act-3")?.scrollIntoView({ behavior:"smooth", block:"start" }), 40);
      else { setOpen(false); window.scrollTo({ top:0, behavior:"smooth" }); }
      return next;
    });
  }, []);

  /* covered set keyed by featured-index for the focus dots */
  const coveredByIndex = new Set(featured.map((id,i)=> covered.has(id) ? i : -1).filter(i=>i>=0));

  /* keyboard */
  useEffect(() => {
    const onKey = (e) => {
      if (e.key === "l" || e.key === "L") { toggleLive(); return; }
      if (!liveRef.current) return;
      if (openRef.current) {
        if (e.key === "ArrowRight") { e.preventDefault(); move(1); }
        else if (e.key === "ArrowLeft") { e.preventDefault(); move(-1); }
        else if (e.key === "Escape") closeFocus();
        else if (e.key === "c" || e.key === "C") coverCurrent();
        else if (e.key === "w" || e.key === "W") wildcard();
        else if (e.key === "+" || e.key === "=") bumpScale(0.1);
        else if (e.key === "-" || e.key === "_") bumpScale(-0.1);
      } else {
        if (e.key === "ArrowRight" || e.key === "ArrowLeft") { e.preventDefault(); openFocus(0); }
        else if (e.key === "w" || e.key === "W") wildcard();
      }
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [toggleLive, move, closeFocus, coverCurrent, wildcard, bumpScale, openFocus]);

  /* reflect theme on body so fixed chrome + grain pick up tokens */
  useEffect(() => { document.body.classList.toggle("live", live); }, [live]);

  return (
    <React.Fragment>
      <Status label={EPISODE.label} clock={clock} />
      <LiveToggle live={live} onToggle={toggleLive} />

      <div className="wrap">
        <header>
          <Kicker>A father–son conversation about A.I.</Kicker>
          <ShowTitle />
          <Deck>Not all the AI news — just what matters, and why. In plain English.</Deck>
          <Epigraph quote="I'll reel you in when you get too nerdy." cite="— Dad, on his job description" />
          <Meta you={EPISODE.hosts.you} dad={EPISODE.hosts.dad} number={EPISODE.number} label={EPISODE.label} date={EPISODE.date} />
        </header>

        <section className="act-1">
          <ActHead roman="I." title="The Setup" note="One clean breath. Who we are, what this is. Keep it short." />
          <Lede first>Two people sit down once a week to make sense of artificial intelligence: <strong>one who follows it closely</strong>, and <strong>one who keeps the other honest</strong>.</Lede>
          <Lede>It's for everyone who keeps hearing "AI" in the news and quietly wonders what's hype, what's real, and what any of it means for them. No jargon survives this table.</Lede>
        </section>

        <section className="act-2">
          <ActHead roman="II." title="This Week" note="A few headlines. What happened, then the only question that matters: so what?" />
          <div className="news">
            {EPISODE.news.map((n, i) => <NewsCard key={i} {...n} />)}
            <NewsBlank onClick={() => {}} />
          </div>
        </section>

        <section className="act-3">
          <ActHead roman="III." title="The Conversation" note="Loose anchors, not a script." />
          <p className="spark-intro rise"><b>Pull one spark and follow the tangent.</b> Each is a door, not a lecture. Glance, riff, let Dad reel it back when it drifts.</p>
          <div className="sparks">
            {featured.map((id, i) => {
              const s = SPARK_LIBRARY[id];
              return <Spark key={id} id={id} index={i} tag={s.tag} prompt={s.prompt} aside={s.aside}
                covered={covered.has(id)} live={live} onCover={toggleCoverId} onOpen={openFocus} />;
            })}
          </div>
        </section>

        <section className="act-archive">
          <ActHead roman="IV." title="The Archive" note="Every episode is a saved copy. The shelf grows on its own." />
          {ARCHIVE.map((a, i) => {
            const tags = a.sparks.map(id => SPARK_LIBRARY[id]?.tag || id).join(" · ");
            return <ArcRow key={i} number={a.number} title={a.title} tags={tags} date={a.date} />;
          })}
        </section>

        <Footer />
      </div>

      <FocusDeck
        open={open} spark={currentSpark} isWild={wild !== null}
        index={index} total={featured.length} covered={coveredByIndex} scale={scale}
        onClose={closeFocus} onPrev={() => move(-1)} onNext={() => move(1)} onDot={openFocus}
        onCover={coverCurrent} onWild={wildcard} onScale={bumpScale}
      />
    </React.Fragment>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
