/* =============================================================
   REEL IT IN — Shared episode data
   Single source of truth for the show document AND the operator
   control dashboard. Exported to window so any text/babel script
   can read it (separate Babel scripts don't share scope).

   Weekly use: duplicate, edit RII_EPISODE, leave the library.
   ============================================================= */

window.RII_SPARKS = {
  "consciousness":  { tag:"The Big One",        prompt:"Is anybody home in there? Is it actually thinking?", aside:"My honest take: no — a brilliant mirror, not a mind. So why does the line feel like it's blurring?" },
  "whose-opinions": { tag:"Under the Hood",     prompt:"The model has no opinions of its own — so whose are coming out of its mouth?", aside:"Whatever it was trained on becomes its worldview. That's why two AIs can answer the same question differently." },
  "oracle":         { tag:"Myth & Machine",     prompt:"People are \u201cpraying\u201d to the machine. Is the prompt box the new oracle?", aside:"A tool, a confessional, or a ritual — and does it know the difference? (It doesn't.)" },
  "old-gods":       { tag:"Old Gods, New Gods",  prompt:"Every age built something to consult the unknown. What does ours say about us?", aside:"Oracles, spirits, daemons — and the silicon version we just quietly invented." },
  "the-state":      { tag:"The State",          prompt:"When the government starts asking the AI for answers, whose answers are they?", aside:"Policy, policing, public services — running on models almost nobody can see inside." },
  "where-it-lives": { tag:"Where It Lives",     prompt:"Soon the AI may live in your pocket instead of a warehouse far away. Better, or just different?", aside:"Data centers, energy, privacy — and why 'where the AI lives' is about to matter to you." },
  "who-owns-temple":{ tag:"Who Owns the Temple", prompt:"A handful of companies own the buildings all of this runs in. Should that worry us?", aside:"Whoever owns the compute owns the answers. The new cathedrals have landlords." },
  "everyday-trust": { tag:"Closer to Home",     prompt:"If a friend gave you the advice the AI just gave you, would you take it?", aside:"How much we already lean on it without noticing — and where that's fine, and where it isn't." },
};

window.RII_EPISODE = {
  number: "001", label: "Pilot", date: "May 29, 2026",
  hosts: { you: "[ you ]", dad: "[ dad ]" },
  news: [
    { source:"Illinois Legislature", url:"#",
      headline:"Illinois becomes the first US state to make big AI labs get outside audits",
      why:"For the first time, an AI company's safety claims have to be checked by someone outside the company — a small but real shift in who gets to call an AI 'safe.'" },
    { source:"Build Fast with AI · May 25", url:"#",
      headline:"Another big employer cut jobs — and AI is the quiet reason",
      why:"It isn't robots taking desks. Companies are doing the same work with smaller teams because AI fills the gap. The pattern, not any one layoff, is the story." },
    { source:"Google I/O 2026", url:"#",
      headline:"Google halved the price of its top AI — and gave it the power to do things for you",
      why:"A capable assistant just got much cheaper and can now act on your behalf — book, browse, buy. The 'AI that does, not just answers' era is arriving for normal people." },
  ],
  featuredSparks: ["consciousness","whose-opinions","oracle","old-gods","the-state","where-it-lives"],

  /* ---- run-of-show: per-act time budgets (minutes) for the dashboard ----
     Act III's budget is spread across its sparks (budgetMin / #sparks). */
  rundown: [
    { act:"I",   title:"The Setup",        kind:"talk",   budgetMin:3,  note:"One clean breath. Who we are." },
    { act:"II",  title:"This Week",        kind:"news",   budgetMin:8,  note:"Three headlines. So what?" },
    { act:"III", title:"The Conversation", kind:"sparks", budgetMin:18, note:"Pull sparks. Follow tangents." },
    { act:"IV",  title:"Wrap",             kind:"talk",   budgetMin:3,  note:"Land it. Tease next week." },
  ],
  targetMin: 32,
};

window.RII_ARCHIVE = [
  { number:"000", title:"The test run that started it all", date:"May 22, 2026", sparks:["oracle","whose-opinions"] },
];
