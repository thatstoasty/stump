"""Compile-test the Mojo code blocks embedded in README.md.

This script scans a Markdown file for fenced ```mojo code blocks, writes each one
to a temporary `.mojo` file, and attempts to compile it with `mojo build`. A
successful build means the example is syntactically valid and type-checks against
the current `stump` package (it does *not* run the example, so no side effects
are triggered).

Usage:
    pixi run mojo -I . utils/test_readme_examples.mojo
    mojo -I . utils/test_readme_examples.mojo --readme README.md --mojo "pixi run mojo"

The exit code is the number of examples that failed to compile (0 = all passed),
so it can be wired into CI directly.
"""

from std.os.path import basename, dirname
from std.pathlib import Path, cwd
from std.subprocess import run
from std.sys import argv, exit
from std.tempfile import TemporaryDirectory, mkdtemp
from std.time import perf_counter

comptime USAGE = String(
    "usage: test_readme_examples.mojo [options]\n"
    "\n"
    "Compile every fenced `mojo` code block in a Markdown file.\n"
    "\n"
    "options:\n"
    "  --readme PATH     Markdown file to scan (default: repo README.md).\n"
    "  --include PATH    Directory passed to `mojo build -I` (default: repo root).\n"
    '  --mojo CMD        Launcher for the mojo compiler (default: "pixi run mojo").\n'
    "  --language TAG    Fenced code-block language tag to test (default: mojo).\n"
    "  --keep            Keep the generated temporary .mojo files.\n"
    "  -h, --help        Show this message and exit.\n"
)

# Sentinel appended to every compile command so the child's exit status survives
# `run()`, which only hands back the command's stdout.
comptime EXIT_MARKER = "__STUMP_EXIT__"


@fieldwise_init
struct CodeBlock(Copyable, Movable):
    """A single fenced code block extracted from a Markdown file."""

    var index: Int
    """1-based ordinal among the matching blocks."""
    var start_line: Int
    """1-based line number of the opening fence in the source."""
    var code: String
    """The block's contents, without the fences."""


@fieldwise_init
struct BlockResult(Copyable, Movable):
    """The outcome of compiling one code block."""

    var block: CodeBlock
    """The block that was compiled."""
    var ok: Bool
    """Whether `mojo build` exited successfully."""
    var output: String
    """Combined stdout/stderr from the compiler."""
    var elapsed: Float64
    """Wall-clock seconds spent in the compiler."""


def find_repo_root(start: Path) raises -> Path:
    """Return the repository root by walking up until a README.md is found.

    Args:
        start: Directory to begin the search from.

    Returns:
        The first ancestor (including `start`) that contains a README.md, or the
        parent of `start` when none is found (utils/ lives at the repo root).
    """
    var candidate = start
    while True:
        if (candidate / "README.md").is_file():
            return candidate
        var parent = Path(dirname(candidate))
        if parent == candidate:
            return Path(dirname(start))
        candidate = parent^


def leading_backticks(line: ImmStringSpan) -> Int:
    """Count the backticks a line starts with.

    Args:
        line: The line to inspect.

    Returns:
        The number of leading backtick characters.
    """
    comptime BACKTICK = Byte(ord("`"))
    var count = 0
    for byte in line.as_bytes():
        if byte != BACKTICK:
            break
        count += 1
    return count


def first_token(text: ImmStringSpan) -> String:
    """Return the first whitespace-delimited token of `text`, lowercased.

    Args:
        text: The text to tokenize.

    Returns:
        The lowercased first token, or an empty string when `text` is blank.
    """
    var stripped = text.strip()
    if not stripped:
        return ""
    return String(stripped.split()[0].lower())


def extract_blocks(markdown: ImmStringSpan, language: ImmStringSpan) -> List[CodeBlock]:
    """Parse fenced code blocks tagged with the given language out of Markdown.

    Handles fences of three or more backticks and ignores nested fences that use
    a different number of backticks. Only the info string's first token is
    matched, so ```mojo and ```mojo title=foo both count.

    Args:
        markdown: The Markdown source to scan.
        language: The info-string tag to match, e.g. "mojo".

    Returns:
        Every matching block, in document order.
    """
    var blocks = List[CodeBlock]()
    var lines = markdown.splitlines()
    var i = 0
    var n = len(lines)
    while i < n:
        var stripped = lines[i].lstrip()
        var fence_size = leading_backticks(stripped)
        if fence_size >= 3:
            var lang = first_token(stripped[byte=fence_size:])
            var start_line = i + 1
            i += 1
            var body = List[String]()
            # Consume until a closing fence of the same length (or EOF).
            while i < n:
                var candidate = lines[i].lstrip()
                if leading_backticks(candidate) == fence_size and not candidate[byte=fence_size:].strip():
                    break
                body.append(String(lines[i]))
                i += 1
            if lang == language:
                blocks.append(CodeBlock(len(blocks) + 1, start_line, String("\n").join(body) + "\n"))
        i += 1
    return blocks^


def compile_block(block: CodeBlock, mojo_cmd: ImmStringSpan, include_path: Path, work_dir: Path) raises -> BlockResult:
    """Write a block to a temporary file and try to compile it.

    Args:
        block: The block to compile.
        mojo_cmd: Shell command that launches the mojo compiler.
        include_path: Directory handed to `mojo build -I`.
        work_dir: Directory the generated sources and binaries are written to.

    Returns:
        The compile outcome, including the compiler's combined output.
    """
    var stem = String("readme_block_", pad_left(String(block.index), 2, "0"))
    var src = work_dir / String(stem, ".mojo")
    var out = work_dir / String(stem, ".bin")
    src.write_text(block.code)

    # `run()` returns stdout only, so fold stderr in and print the status code.
    var command = String(
        mojo_cmd,
        " build -I ",
        quote(String(include_path)),
        " ",
        quote(String(src)),
        " -o ",
        quote(String(out)),
        " 2>&1; echo ",
        EXIT_MARKER,
        "$?",
    )
    var start = perf_counter()
    var raw = run(command)
    var elapsed = perf_counter() - start

    var marker = raw.rfind(EXIT_MARKER)
    var ok = False
    var output = raw
    if marker != -1:
        ok = String(raw[byte = marker + EXIT_MARKER.byte_length() :]).strip() == "0"
        output = String(raw[byte=:marker])
    return BlockResult(block.copy(), ok, String(output.strip()), elapsed)


def quote(text: ImmStringSpan) -> String:
    """Wrap `text` in single quotes so the shell treats it as one word.

    Args:
        text: The word to quote.

    Returns:
        A single-quoted, shell-safe rendering of `text`.
    """
    return String("'", text.replace("'", "'\\''"), "'")


def pad_left(text: ImmStringSpan, width: Int, fill: ImmStringSpan = " ") -> String:
    """Right-align `text` within `width` characters.

    Args:
        text: The text to pad.
        width: The minimum resulting width.
        fill: The padding character.

    Returns:
        `text` prefixed with enough `fill` characters to reach `width`.
    """
    var missing = width - len(text.codepoints())
    return String(fill * missing if missing > 0 else "", text)


def pad_right(text: ImmStringSpan, width: Int) -> String:
    """Left-align `text` within `width` characters.

    Args:
        text: The text to pad.
        width: The minimum resulting width.

    Returns:
        `text` followed by enough spaces to reach `width`.
    """
    var missing = width - len(text.codepoints())
    return String(text, " " * missing if missing > 0 else "")


def format_seconds(value: Float64) -> String:
    """Render a duration with two decimal places.

    Args:
        value: The duration in seconds.

    Returns:
        The duration formatted as `S.SS`.
    """
    var hundredths = Int(value * 100.0 + 0.5)
    return String(hundredths // 100, ".", pad_left(String(hundredths % 100), 2, "0"))


def indent(text: ImmStringSpan, prefix: ImmStringSpan = "    ") -> String:
    """Prefix every line of `text`.

    Args:
        text: The text to indent.
        prefix: The prefix to add to each line.

    Returns:
        The indented text.
    """
    var lines = List[String]()
    for line in text.splitlines():
        lines.append(String(prefix, line))
    return String("\n").join(lines)


def run_all(
    blocks: List[CodeBlock],
    mojo_cmd: ImmStringSpan,
    include_path: Path,
    work_dir: Path,
    label: ImmStringSpan,
) raises -> List[BlockResult]:
    """Compile each block, printing a live PASS/FAIL line, and collect results.

    Args:
        blocks: The blocks to compile.
        mojo_cmd: Shell command that launches the mojo compiler.
        include_path: Directory handed to `mojo build -I`.
        work_dir: Directory the generated sources and binaries are written to.
        label: Source file name used in the printed location of each block.

    Returns:
        One result per block, in the order they were compiled.
    """
    var results = List[BlockResult]()
    for ref block in blocks:
        var result = compile_block(block, mojo_cmd, include_path, work_dir)
        print(
            String(
                "[",
                "PASS" if result.ok else "FAIL",
                "] block #",
                pad_left(String(block.index), 2),
                "  (",
                label,
                ":",
                pad_right(String(block.start_line), 4),
                ")  ",
                pad_left(format_seconds(result.elapsed), 6),
                "s",
            )
        )
        results.append(result^)
    return results^


def main() raises:
    var script_dir = Path(dirname(cwd() / String(argv()[0])))
    var default_root = find_repo_root(script_dir)

    var readme = default_root / "README.md"
    var include = default_root
    var mojo_cmd = "pixi run mojo"
    var language = "mojo"
    var keep = False

    var args = argv()
    var i = 1
    while i < len(args):
        ref flag = args[i]
        if flag == "-h" or flag == "--help":
            print(USAGE)
            return
        if flag == "--keep":
            keep = True
            i += 1
            continue
        if i + 1 >= len(args):
            print("error: missing value for", flag)
            exit(2)

        ref value = args[i + 1]
        if flag == "--readme":
            readme = Path(value)
        elif flag == "--include":
            include = Path(value)
        elif flag == "--mojo":
            mojo_cmd = String(value)
        elif flag == "--language":
            language = String(value)
        else:
            print("error: unrecognized argument:", flag)
            print(USAGE)
            exit(2)
        i += 2

    if not readme.is_file():
        print("error: README not found:", readme)
        exit(2)

    var blocks = extract_blocks(readme.read_text(), language)
    if not blocks:
        print(String("No `", language, "` code blocks found in ", readme, "."))
        return

    print(String("Testing ", len(blocks), " `", language, "` block(s) from ", readme, "\n"))

    var label = basename(readme)
    var results = List[BlockResult]()
    if keep:
        # `mkdtemp` leaves the directory behind for inspection.
        var work_dir = Path(mkdtemp(prefix="stump_readme_"))
        results = run_all(blocks, mojo_cmd, include, work_dir, label)
        print("\nGenerated files kept in:", work_dir)
    else:
        with TemporaryDirectory(prefix="stump_readme_") as work_dir:
            results = run_all(blocks, mojo_cmd, include, Path(work_dir), label)

    var failures = 0
    for result in results:
        if not result.ok:
            failures += 1

    print(String("\n", "=" * 60))
    print(
        String(
            "Results: ",
            len(results) - failures,
            "/",
            len(results),
            " passed, ",
            failures,
            " failed",
        )
    )
    for ref result in results:
        if not result.ok:
            print(
                String(
                    "\n--- FAILED: block #",
                    result.block.index,
                    " (",
                    label,
                    ":",
                    result.block.start_line,
                    ") ---",
                )
            )
            print(indent(result.output if result.output else "(no compiler output)"))

    exit(failures)
