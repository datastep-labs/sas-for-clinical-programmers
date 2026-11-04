# Start here: SAS for Clinical Programmers, in your browser

> **You see this page as plain text?** Press **Ctrl+Shift+V** (on a Mac **Cmd+Shift+V**) to read it formatted, with
> links you can click.

This is the lab for the free book [SAS for Clinical Programmers](https://sas-for-clinical-programmers.pages.dev/).
Everything is ready in this window: **DataStep Studio**, the **134 programs of the book**, and a connection to **SAS
OnDemand for Academics**. You install nothing.

You will learn SAS the way the book teaches it: you do not only run a program and read the log, you **watch it run**.
You step through a DATA step and see each variable change, you stop inside a macro loop and ask questions, and you
find a wrong count in the data before you write the program.

The lab below takes about **30 minutes**. Each stop shows one thing that changes how you work, with the book's own
programs and data. Then go on with the book, chapter by chapter.

> **What you need:** a free [SAS OnDemand for Academics](https://welcome.oda.sas.com) account. Signing up takes a few
> minutes. Keep your user ID (or the e-mail address you sign in with) and your password at hand.

---

## Stop 0: connect to SAS OnDemand (2 minutes)

The first time you open the codespace:

1. If VS Code asks **Do you trust the authors of the files in this folder?**, choose **Trust Folder & Continue**.
2. Press **F1**, type `reload window`, and choose **Developer: Reload Window**. This is needed once: DataStep Studio
   is installed while the window opens, and only after the reload are the SAS programs in color.

Then connect. **If you entered your user ID and home region** when you made the codespace (`SAS_ODA_USER` and
`SAS_ODA_REGION`), the connection is ready: DataStep Studio says *The connection profile "SAS OnDemand" from the
setup is added and is active*. Click **Connect Now** and type your password. Otherwise:

3. Press **F1**, type `connection profile`, and choose **DataStep Studio: Add New Connection Profile**.
4. Choose **SAS OnDemand for Academics**, then your **home region**. It is in the web address of SAS Studio: an
   address that starts with `https://odamid-euw1.oda.sas.com` means Europe 1 (`euw1`).
5. Type your SAS OnDemand **user ID** or the **e-mail address** you sign in with, and choose **Connect Now**.
6. Type your password. It is kept for this codespace, so you type it once.

**What you should see:** after a few seconds, the **Libraries** view on the right lists the libraries of your SAS
session (WORK, SASHELP and others).

Not sure about a step? Press **F1** and choose **DataStep Studio: Check Setup**: it says what is ready and what is
missing.

## Stop 1: get the study data (1 minute)

Open [programs/00_setup.sas](programs/00_setup.sas) and press **F4**.

**What you should see:** the **SAS Log** fills, and the log ends without an ERROR. The program downloads the CDISC
pilot study (254 subjects, real SDTM and ADaM data) into your SAS OnDemand home folder and makes two libraries:
`SDTM` and `REFADM`. You do this once. In a new SAS session, run
[programs/00_libs.sas](programs/00_libs.sas) first: it connects the two libraries again.

## Stop 2: look at the data before you write code (5 minutes)

*The question:* how many subjects had a **severe** treatment-emergent adverse event, by treatment?

1. Open the **Libraries** view on the right, open **REFADM**, and double-click **ADAE**.
   **What you should see:** 1191 rows, like VIEWTABLE.
2. Press **w** and type `trtemfl = "Y" AND aesev = "SEVERE"`, then **Enter**.
   **What you should see:** 41 rows.
3. Click a cell in the column **TRTA** and press **f**.
   **What you should see:** Placebo 6, Xanomeline High Dose 10, Xanomeline Low Dose 25. These are records.
4. Click a cell in **USUBJID** and press **f**.
   **What you should see:** some subjects have 2 or 3 records. So the number of *subjects* is smaller than 41.

You found the trap before you wrote a line of code: count distinct subjects, not records.
Press **?** in the data viewer to see every key.
Read more: [chapter 21, Look at your data](https://sas-for-clinical-programmers.pages.dev/studio/look-at-data/).

## Stop 3: run exactly the code you want (3 minutes)

Open [programs/04_first_last.sas](programs/04_first_last.sas).

1. Put the cursor in the PROC SORT and click **Run Step** in the title bar of the program. A list asks which part to
   run: choose **PROC SORT**.
   **What you should see:** `NOTE: The data set WORK.AE2 has 7 observations`. Only that step ran.
2. Press **F12**.
   **What you should see:** `WORK.AE2`, the data set the step just made, opens in the data viewer.
3. Put the cursor on the last `RUN;` and press **Ctrl+Alt+Up** (Run To Line).
   **What you should see:** the program runs from the top to the cursor.

When a log has an ERROR, click it: DataStep Studio jumps to the line in your program. **▲ Error** and **Error ▼**
in the SAS Log go from one problem to the next.
Read more: [chapter 20, The daily loop](https://sas-for-clinical-programmers.pages.dev/studio/daily-loop/).

## Stop 4: watch a DATA step run, one statement at a time (5 minutes)

Still in [programs/04_first_last.sas](programs/04_first_last.sas):

1. Put the cursor in the DATA step and click **Debug DATA Step** in the title bar of the program.
   **What you should see:** the first line of the step is marked. The **Variables** view shows the program data
   vector (PDV): `usubjid`, `aedecod`, `aestdtc`, `n_ae`, and the flags `FIRST.usubjid` and `LAST.usubjid`.
2. Press **F10** until the line `n_ae + 1;` has run.
   **What you should see:** on the first record `FIRST.usubjid = 1` and `n_ae = 1`.
3. Click in the margin left of the line `IF LAST.usubjid THEN OUTPUT;` to set a breakpoint. Right-click the red dot,
   choose **Edit Breakpoint…**, and type `usubjid = "01-701-1023"`. Press **F5** (or the **Continue** button ▷ in the
   small debug toolbar at the top).
   **What you should see:** the debugger stops on the first record of subject 01-701-1023, and `n_ae = 1`: the
   counter started again, because `FIRST.usubjid = 1`.
4. Press **F5** three more times.
   **What you should see:** `n_ae` goes 2, 3, 4. On the last stop `LAST.usubjid = 1`, so this record is written.
5. Right-click the red dot and choose **Remove Breakpoint**. Press **F5** until the step ends.

This is how SAS really reads your step, record by record. No `PUT _ALL_` lines, no run after run.
Read more: [chapter 23, Debug a DATA step](https://sas-for-clinical-programmers.pages.dev/studio/debug-data-step/).

## Stop 5: stop inside a macro and ask questions (5 minutes)

Open [programs/24_pry_practice.sas](programs/24_pry_practice.sas). The macro makes one subset per severity and counts
the subjects.

1. Press **F4**.
   **What you should see:** three NOTEs in the log: `MILD: 187`, `MODERATE: 130` and `SEVERE: 29` subjects.
2. Replace the comment on line 10 with `%pry(when=&i. = 3)` and press **F4** again. (The codespace saves your change
   by itself.)
   **What you should see:** the run stops in the third round of the loop. The **SAS Pry** terminal opens with the
   prompt `pry(%by_sev)>`.
3. Type `ls` and press **Enter**.
   **What you should see:** the macro variables of `%by_sev`: `i = 3`, `sev = SEVERE`, and `nsub = 130`, the value
   of round 2, because the PROC SQL of round 3 has not run yet.
4. Type `vt _sev`.
   **What you should see:** the first 20 rows of `WORK._SEV` (41 rows now), and the data set opens in the data
   viewer.
5. Type `c`.
   **What you should see:** the run goes on, and the log gets `NOTE: SEVERE: 29 subjects with a treatment-emergent AE`.

`%pry` is a stop you write into the code, like a `%PUT` that waits for you.
Read more: [chapter 24, %pry](https://sas-for-clinical-programmers.pages.dev/studio/pry/).

## Stop 6: debug a macro with breakpoints (5 minutes)

Undo the change on line 10 of [programs/24_pry_practice.sas](programs/24_pry_practice.sas) (**Ctrl+Z**, on a Mac
**Cmd+Z**), so the comment is back.

1. Put the cursor in `%by_sev` and click **Debug Macro** in the title bar.
   **What you should see:** a call pane above the macro, with its parameters `data` and `sevs` ready.
2. Click in the margin of the line `%LET sev = %SCAN(&sevs., &i., %STR( ));`. Right-click the red dot, choose
   **Edit Breakpoint…**, and type `&i. = 3`.
3. Click the blue **Start Debug** button in the title bar of the call pane, then press **F5**.
   **What you should see:** the stop in round 3: `i = 3`, but `sev = MODERATE`. The `%LET` has not run yet.
4. Press **F10**.
   **What you should see:** `sev = SEVERE`.
5. In the **Debug Console**, type `%EVAL(&i. * 2)`.
   **What you should see:** `6`. The console works inside the paused macro.
6. Right-click the red dot, choose **Remove Breakpoint**, and press **F5** to the end.
   **What you should see:** at the end of each line of the macro, how often it ran: `×3` inside the loop, `×1`
   before it.

Read more: [chapter 25, Debug a macro](https://sas-for-clinical-programmers.pages.dev/studio/debug-macro/).

## Stop 7: write SAS faster (3 minutes)

Make a new file: in the **Explorer** on the left, right-click the folder **programs**, choose **New File…**, and
type `try.sas`. Then try these:

| Type | Then | You get |
|---|---|---|
| `proc so` | **Enter** | a PROC SORT step; **Tab** jumps to the next field |
| `firstlast` | wait until the suggestion shows, then **Tab** | a PROC SORT and a DATA step with `BY`, `FIRST.` and `LAST.` |
| `DATA pbo; SET refadm.adsl; WHERE trt01p = '` | (wait) | the values of the column, most frequent first |
| any procedure name | **Ctrl+Space** | the options of the procedure, with help |

Read more: [chapter 22, Write faster](https://sas-for-clinical-programmers.pages.dev/studio/write-faster/).

## Stop 8: your turn, find the wrong number

Open [programs/26_1_count_wrong.sas](programs/26_1_count_wrong.sas). The statistician says: *"Low dose: the number of
subjects should be 16, not 25."* The log is clean. Find out why with what you learned in stops 2 and 5, then compare
with [programs/26_2_count_right.sas](programs/26_2_count_right.sas).
The answer: [chapter 26.2](https://sas-for-clinical-programmers.pages.dev/studio/workflows/#262-why-is-my-count-25-and-not-16).

---

## Go on with the book

The programs are named by chapter: `04_first_last.sas` belongs to chapter 4, and inside a chapter the file order is
the run order. Read a chapter in the [book](https://sas-for-clinical-programmers.pages.dev/), open its programs here,
and step through them. Every program ran in DataStep Studio on SAS OnDemand before the book was published, so you
should get the same results.

The [cheat sheet](https://sas-for-clinical-programmers.pages.dev/studio/cheat-sheet/) lists every key on one page.
**F9** opens the **Keys** tab, where you can change any key.

## Good to know

* **Your work is kept.** A codespace stops by itself after a while without use. Your files stay; open it again from
  [github.com/codespaces](https://github.com/codespaces). The data you made with `00_setup.sas` is in your SAS
  OnDemand home folder, not here.
* **It is free for you.** Each free GitHub account includes a monthly amount of codespace time (at the time of
  writing 120 core hours, about 60 hours on this 2-core machine). Without a payment method on your GitHub account,
  you are never charged: the codespace stops when the free time is used up.
* **Your changes are saved by themselves.** To get a book program back as it was, open the **Source Control** view
  on the left, right-click the file, and choose **Discard Changes**.
* **In the browser, a few keys belong to the browser** (for example **Ctrl+W** closes the tab). On a Mac keyboard,
  the F keys may need **fn** (for example **fn+F5**). The VS Code desktop app has none of these limits: install
  DataStep Studio there from the Extensions view when you want to work on your own computer.
* **The count at the top right of the SAS Log** (`0 error(s), 0 warning(s)`) is for the whole log of the session.
  The **Suspicious Log** tab lists every ERROR, WARNING and notable NOTE, each with its program and line.
* **Professional features** (both debuggers, `%pry`, and some of the writing help) are free during Early Access.
