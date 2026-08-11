# Amiga Reconstructed Source Codes

This repository collects reconstructed source code for Amiga software and
systems of historical or reverse-engineering interest.

The goal is preservation and study: to make recovered or reconstructed code
easier to inspect, compare, document, and discuss. It is not intended to be a
drop-in upstream source tree, a complete build environment, or a distribution of
original commercial releases.

## Scope

This project is for material such as:

- Reconstructed Amiga source code derived from binaries, disks, ROMs, or other
  historical artifacts.
- Notes that explain reconstruction decisions, symbol naming, memory maps,
  calling conventions, file formats, or hardware behavior.
- Build scripts or metadata that help verify a reconstruction against an
  original binary when that is possible.
- Documentation that helps future readers understand how a source tree relates
  to the original artifact.

Where possible, each reconstruction should explain:

- What original program, version, disk, ROM, or binary it corresponds to.
- How complete or speculative the reconstruction is.
- Which tools were used.
- Whether the result has been assembled or compiled successfully.
- Whether the generated output has been compared with the original.

## Current Content

### Amiga Intros and Trainermenus

|          Name           |    Author     |   Group    | Comments                                                 |
| :---------------------: | :-----------: | :--------: | :------------------------------------------------------- |
|    Liberation Intro     |    Madison    |  Delirium  | Cracktro for the game Liberation                         |
|  King of Chicago Intro  |     Gary      |    HQC     | Cracktro for the game King of Chicago                    |
|   Dune 2 Trainermenu    |   Colorboy    |   Mystic   | Trainermenu for the game Dune 2                          |
| Miami Chase Trainermenu | Phil Douglas  |            | Trainermenu for the game Miami Chase incl. trainer patch |
|    Sidewinder Intro     |   Dr. Pablo   | The Champs | Cracktro for the game Sidewinder                         |
| Rick Dangerous Trainer  |   Weetibix    |   Oracle   | Trainermenu for the game Rick Dangerous                  |
|  Beneath the Steel Sky  | Wayne Mendoza |  Delirium  | Cracktro for Beneath the Steel Sky by Masque             |
|   Robocod Trainermenu   | Surprise!Prod |    TRSI    | Trainermenu for Robocod                                  |
|   Turrican Trainermenu  | TRANSFORMER   |    TRSI    | 100% Trainer Intro for Turrican 1                        |
|  Emetic Skimmer Intro   |               | The Movers | Cracktro for the game Emetic Skimmer                     |

### Tools

|       Name        |       Author        |      Group      | Comments                                 |
| :---------------: | :-----------------: | :-------------: | :--------------------------------------- |
| RSI Cruncher v1.4 |        Flash        | Red Sector Inc. | Full source code of the cruncher         |
|  Tetrapack v2.2   |     Antiaction      |     Defjam      | Full source code of the cruncher         |
|   Double Action   |        Vince        |     Tristar     | Full source code of the cruncher         |
|   Beermon v0.45   | Carnivore/Beermacht |      TRSI       | Full source code of the monitor (Moni.s) |

## Repository Status

This repository is currently a container for reconstructed Amiga source material.
Individual source trees may vary in completeness and accuracy.

Expect some code to be incomplete, partially named, tool-specific, or annotated
with reverse-engineering notes. Treat reconstructed sources as research material
unless a directory explicitly documents a verified build.

## Suggested Layout

For consistency, new reconstructions should use a structure similar to this:

```text
project-name/
  README.md          Project-specific notes and verification status
  src/               Reconstructed source files
  include/           Shared declarations, if applicable
  build/             Build scripts or assembler/compiler configuration
  docs/              Analysis notes, maps, tables, and references
  tools/             Helper scripts used during reconstruction
```

Small reconstructions do not need every directory, but each contribution should
include enough context for another person to understand what the files represent.

## Working With The Code

Because Amiga software was built with many different assemblers, compilers,
linkers, operating system versions, and hardware assumptions, there is no single
global build command for this repository.

Check the `README.md` inside an individual reconstruction directory for:

- Required tools.
- Expected host platform.
- Build or assembly commands.
- Known missing pieces.
- Verification procedure.

If no project-specific README exists, assume the material is for reading and
analysis only.

## Legal And Preservation Notes

Reconstructed source code can have complicated copyright and licensing status.
Only add material that you have the right to publish, or that can otherwise be
shared lawfully.

When contributing, include provenance and licensing notes whenever possible. If a
file is based on analysis of an original binary or disk image, document that
clearly. Do not include original commercial binaries, disk images, ROM images, or
other copyrighted artifacts unless their redistribution is explicitly permitted.

## Contributing

Useful contributions include:

- Adding a new reconstruction with clear provenance notes.
- Improving symbol names, comments, labels, or structure.
- Adding build instructions for a known toolchain.
- Adding verification notes or binary comparison results.
- Correcting inaccurate assumptions in existing analysis.

Please keep historical notes factual and separate confirmed information from
inference. If a name, type, or behavior is guessed, mark it as such.

## Audience

This repository is mainly for:

- Amiga historians and preservationists.
- Reverse engineers.
- Emulator and tool authors.
- Developers studying Amiga hardware, operating system internals, file formats,
  or period-specific development techniques.

The emphasis is on clarity, traceability, and preservation value.
