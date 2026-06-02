# Reel It In Context

Reel It In is a father-son AI show production system. This context names the show, episode, and automation terms that future agents should use when improving the repo.

## Language

**Reel It In**:
A father-son conversation show that makes fast-moving AI news understandable, human, and worth caring about.
_Avoid_: AI news site, tech analyst broadcast

**Shane**:
The host who follows AI closely and translates fast-moving technical material into plain English.
_Avoid_: expert narrator, solo presenter

**Dad**:
The co-host and listener proxy who keeps the conversation grounded by asking why a story matters.
_Avoid_: guest, novice, senior audience

**Episode**:
One recorded installment of the show, with its own selected stories, sparks, notes, handoffs, publishing package, and archive metadata.
_Avoid_: show page, project, release

**Episode Folder**:
The per-episode folder under `episodes/` that holds source links, prep, generated handoffs, publishing files, and archive metadata for one Episode.
_Avoid_: Episode Workspace, workspace, project folder

**Story**:
A sourced AI news item or event considered for an Episode.
_Avoid_: headline, article, link

**Story Slate**:
The chosen group of three to five Stories for an Episode.
_Avoid_: topic list, agenda

**Spark**:
A strong conversation prompt or framing device that opens a tangent without scripting the hosts.
_Avoid_: segment script, lecture topic

**Episode Angle**:
The main editorial frame Shane chooses for one Episode.
_Avoid_: theme when the meaning is the host's editorial take

**Why-It-Matters**:
The plain-English consequence of a Story for normal listeners.
_Avoid_: analysis, take, commentary

**So What?**:
The landed practical meaning after Shane explains and Dad reels the conversation back.
_Avoid_: conclusion, summary

**Dad Question**:
A natural question Dad might ask to clarify why a Story matters.
_Avoid_: interview question, prompt script

**Dad Brief**:
The lightweight Dad-facing prep file for an Episode.
_Avoid_: research dump, show notes, repo access

**Dad Packet**:
The generated handoff file that packages Dad-facing prep for sharing.
_Avoid_: Dad Brief when referring to the generated packet

**Operator Dashboard**:
The host-operated prep and live recording surface used by Shane.
_Avoid_: public site, marketing page

**Handoff Packet**:
A generated file that packages Episode material for a specific recipient or production lane.
_Avoid_: artifact, export when the recipient matters

**Episode Pipeline**:
The automated sequence that checks and regenerates Episode artifacts.
_Avoid_: Automation Pipeline

**Production Brain**:
The git repo and GitHub source of truth for text, code, planning, metadata, source links, templates, automation scripts, and decisions.
_Avoid_: media vault, shared drive

**Production Vault**:
The external cloud media folder that holds raw and exported audio, video, thumbnails, transcripts, and rendered media.
_Avoid_: git repo, source of truth

**Episode Archive**:
The saved Episode record with sources, notes, final metadata, and links.
_Avoid_: retired artifact archive

**Retired Artifact Archive**:
The repo area for old generated artifacts or published snapshots that are no longer active source of truth.
_Avoid_: Episode Archive

## Relationships

- **Reel It In** produces many **Episodes**.
- A **Solo Reaction Episode** is still an **Episode**, but it centers one **Source Video** instead of a three-to-five-story **Story Slate**.
- **YouTube University Ingest** prepares external transcript artifacts for a **Source Video**; the **Episode Folder** links to those artifacts instead of storing them.
- One **Episode** belongs to exactly one **Episode Folder**.
- An **Episode Folder** contains one **Story Slate**, zero or more **Sparks**, one **Dad Brief**, and generated **Handoff Packets**.
- A **Story Slate** contains three to five **Stories**.
- Each **Story** should have a **Why-It-Matters** and may have a **Dad Question**.
- **Shane** chooses the **Episode Angle** and operates the **Operator Dashboard**.
- **Dad** receives a **Dad Brief** or **Dad Packet**, not repo access.
- The **Episode Pipeline** reads and writes files in the **Episode Folder**.
- The **Production Brain** stores text and structured artifacts; the **Production Vault** stores large media.
- An **Episode Archive** records the finished Episode; the **Retired Artifact Archive** stores obsolete repo artifacts.

## Example dialogue

> **Dev:** "Should I put the Riverside download in the **Episode Folder** so the **Episode Pipeline** can package it?"
> **Domain expert:** "No. The **Episode Folder** gets source links, prep, notes, handoffs, and metadata. Raw media belongs in the **Production Vault**, with links recorded in the **Episode Archive**."
>
> **Dev:** "Should the **Dad Brief** include every source from the **Story Slate**?"
> **Domain expert:** "No. Dad needs the **Episode Angle**, plain-English **Stories**, **Why-It-Matters**, and maybe a **Dad Question**. He does not need a research dump."

## Flagged ambiguities

- "workspace" means the whole local repo checkout. The per-episode unit is an **Episode Folder**.
- "archive" has two meanings. Use **Episode Archive** for finished episode records and **Retired Artifact Archive** for old repo artifacts.
- **Dad Brief** and **Dad Packet** are related but not identical: the brief is the Dad-facing prep file, and the packet is a generated handoff.
