# nf-basecall

A Nextflow DSL2 pipeline for Oxford Nanopore sequencing data basecalling using [Dorado](https://github.com/nanoporetech/dorado). Supports simplex and duplex basecalling, modified base detection, inline alignment, barcode demultiplexing, poly-A estimation, read error correction, and full GPU/HPC integration.

## Features

- **Simplex & duplex basecalling** — `hac`, `sup`, `fast`, or full versioned model names
- **Modified base detection** — 5mCG, 5hmCG, 6mA, 5mC, and combinations
- **Inline alignment** — basecall and align in a single pass via minimap2
- **Barcode demultiplexing** — classify reads during basecalling, split into per-barcode sorted BAMs
- **Poly-A tail estimation** — length written to `pt` BAM tag
- **Move table output** — `mv` tag for downstream signal-level tools (e.g. Remora)
- **Read error correction** — HERRO deep-learning algorithm (`dorado correct`)
- **Quality filtering** — discard reads below a minimum Q-score threshold
- **Multiple output formats** — BAM (default), FASTQ, SAM, CRAM
- **Automatic read-level summary** — TSV generated after every basecalling job
- **Parallel processing** — automatically parallelises over barcode/sample subdirectories
- **GPU acceleration** — multi-GPU (`cuda:all`), auto batch-size tuning, Apple Silicon support
- **HPC-ready** — SLURM profile with per-process GPU and resource allocation
- **Container support** — Docker and Singularity profiles

## Quick start

```bash
# Simplex basecalling (HAC model, BAM output)
nextflow run main.nf \
  --input /data/pod5 \
  --model hac \
  --outdir results

# With GPU and Docker
nextflow run main.nf \
  --input /data/pod5 \
  --model hac \
  --outdir results \
  -profile gpu,docker
```

## Requirements

- [Nextflow](https://nextflow.io/) >= 23.04
- [Dorado](https://github.com/nanoporetech/dorado) (via Docker/Singularity or installed locally)
- NVIDIA GPU strongly recommended for practical throughput

## Installation

```bash
git clone https://github.com/reubenduncan/nf-basecall.git
cd nf-basecall
```

## Input structure

The pipeline accepts two input layouts:

**Per-sample/barcode subdirectories** (processed in parallel):
```
pod5_pass/
  barcode01/  *.pod5
  barcode02/  *.pod5
  barcode03/  *.pod5
```

**Flat directory** (processed as a single job):
```
pod5_pass/
  read_001.pod5
  read_002.pod5
```

The pipeline auto-detects which layout is present.

## Parameters

### Input / output

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--input` | required | Path to POD5 directory or parent of barcode subdirs |
| `--outdir` | `results` | Output directory |

### Basecalling

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--model` | `hac` | Model: `fast`, `hac`, `sup`, or a full name e.g. `dna_r10.4.1_e8.2_400bps_hac@v5.0.0` |
| `--modified_bases` | — | Modified base models, comma-separated: `5mCG_5hmCG`, `6mA`, `5mC_5hmC`, etc. |
| `--models_directory` | — | Local directory for model cache (or set `DORADO_MODELS_DIRECTORY`) |
| `--min_qscore` | `0` | Minimum mean Q-score; reads below threshold are discarded (0 = no filter) |
| `--estimate_poly_a` | `false` | Estimate poly-A tail length (written to `pt` BAM tag) |
| `--recursive` | `false` | Recursively scan input directory for POD5 files |
| `--read_ids` | — | File of read IDs to process (newline-delimited) |
| `--max_reads` | — | Hard cap on the number of reads processed |
| `--resume_from` | — | Path to an existing partial BAM to resume an interrupted job |
| `--emit_moves` | `false` | Write signal move table to `mv` BAM tag (required by Remora) |
| `--emit_summary` | `false` | Write `sequencing_summary.txt` inline during basecalling |

### Output format

Only one format flag may be set at a time. Default is BAM.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--emit_fastq` | `false` | Output FASTQ instead of BAM |
| `--emit_sam` | `false` | Output SAM instead of BAM |
| `--emit_cram` | `false` | Output CRAM instead of BAM |

### Alignment

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--reference` | — | Reference FASTA/FASTQ/.mmi for inline alignment during basecalling |
| `--bed_file` | — | BED file; overlap counts written to `bh` BAM tag (requires `--reference`) |
| `--mm2_opts` | — | Custom minimap2 options overriding the `lr:hq` preset, e.g. `'-k 15 -w 10'` |

### Trimming

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--trim` | `adapters` | Trim mode: `adapters`, `all` (adapters + primers + barcodes), `none` |
| `--no_trim` | `false` | Disable all trimming (equivalent to `--trim none`) |

> When `--kit_name` is set, trimming is automatically disabled during basecalling to preserve barcodes for the demultiplexing step.

### Barcode demultiplexing

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--kit_name` | — | Barcode kit name, e.g. `SQK-RBK114-96`, `SQK-NBD114-24` |
| `--barcode_both_ends` | `false` | Require a barcode on both ends of the read |
| `--barcode_arrangement` | — | Path to a custom barcode arrangement file |
| `--barcode_sequences` | — | Path to a custom barcode sequences file |

When `--kit_name` is provided the basecaller classifies reads and a `DORADO_DEMUX` step splits the output into per-barcode sorted BAMs with an accompanying `sequencing_summary.txt`.

### Duplex basecalling

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--duplex` | `false` | Use `dorado duplex` instead of `dorado basecaller` |
| `--pairs_file` | — | CSV of template/complement read ID pairs (auto-detected if omitted) |

> `--duplex` and `--correct` cannot be used together.

### Read error correction

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--correct` | `false` | Run `dorado correct` (HERRO algorithm) on the basecalled reads |
| `--paf_file` | — | Pre-computed PAF file (skips internal alignment step) |

> `dorado correct` requires substantial resources: >= 64 CPU cores, >= 256 GB RAM, >= 32 GB GPU VRAM. Input reads should be >= 10 kbp with >= 30x coverage.

### Performance tuning

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--device` | auto | Device: `cuda:all`, `cuda:0`, `cuda:0,2`, `cpu`, `metal`. Set to `cuda:all` by the `gpu` profile |
| `--batchsize` | `0` | Chunks per batch. `0` = auto-tune from available GPU memory |
| `--chunksize` | Dorado default (10000) | Chunk size in samples |
| `--overlap` | Dorado default (500) | Overlap between chunks in samples |
| `--num_runners` | auto | Parallel neural-network runners per device |

## Execution profiles

Profiles can be combined with a comma, e.g. `-profile gpu,docker` or `-profile slurm,gpu,singularity`.

| Profile | Description |
|---------|-------------|
| `gpu` | Sets `--device cuda:all` and requests GPU resources; pairs with `docker` or `singularity` |
| `docker` | Runs all processes in `ontresearch/dorado:latest` via Docker |
| `singularity` | Runs all processes in `docker://ontresearch/dorado:latest` via Singularity |
| `slurm` | Submits jobs to a SLURM cluster on the `gpu` queue with per-process resource allocations |

## Usage examples

```bash
# HAC basecalling with GPU and Docker
nextflow run main.nf \
  --input /data/pod5 --model hac \
  -profile gpu,docker

# Super-accuracy with CpG methylation detection and inline alignment
nextflow run main.nf \
  --input /data/pod5 \
  --model sup \
  --modified_bases 5mCG_5hmCG \
  --reference /data/ref/genome.fa \
  -profile gpu,docker

# Barcode demultiplexing (96-plex rapid kit)
nextflow run main.nf \
  --input /data/pod5 \
  --model hac \
  --kit_name SQK-RBK114-96 \
  -profile gpu,docker

# Duplex basecalling
nextflow run main.nf \
  --input /data/pod5 \
  --model hac \
  --duplex \
  -profile gpu,docker

# FASTQ output with quality filtering
nextflow run main.nf \
  --input /data/pod5 \
  --model hac \
  --emit_fastq \
  --min_qscore 8 \
  -profile gpu,docker

# Full-featured: SUP + mods + alignment + demux + poly-A
nextflow run main.nf \
  --input /data/pod5 \
  --model sup \
  --modified_bases 5mCG_5hmCG,6mA \
  --reference /data/ref/genome.fa \
  --kit_name SQK-RBK114-96 \
  --estimate_poly_a \
  --min_qscore 8 \
  --emit_moves \
  -profile gpu,docker

# HPC cluster (SLURM) with Singularity
nextflow run main.nf \
  --input /data/pod5 \
  --model hac \
  -profile slurm,gpu,singularity

# Resume an interrupted run
nextflow run main.nf \
  --input /data/pod5 \
  --model hac \
  --resume_from /data/results/sample/partial.bam \
  -profile gpu,docker
```

## Outputs

All outputs are written to `--outdir/<sample_id>/`.

| File | Description |
|------|-------------|
| `<sample_id>.bam` | Basecalled reads (BAM, default) |
| `<sample_id>.fastq` | Basecalled reads (when `--emit_fastq`) |
| `<sample_id>_summary.tsv` | Per-read statistics from `dorado summary` |
| `<sample_id>_dorado.log` | Dorado stderr log |
| `demux/<barcode>.bam` | Per-barcode BAMs (when `--kit_name` is set) |
| `demux/sequencing_summary.txt` | Barcode classification summary |
| `<sample_id>_corrected.fasta` | Error-corrected reads (when `--correct`) |
| `pipeline_info/` | Nextflow execution report, timeline, and trace |

## Workflow overview

```
Input (auto-detect: flat dir or per-barcode subdirs)
    │
    ├─ --duplex ──────────→ DORADO_DUPLEX
    └─ (default) ─────────→ DORADO_BASECALL
                                │
                ┌───────────────┼──────────────────┐
                ↓               ↓                  ↓
         DORADO_SUMMARY    DORADO_DEMUX       DORADO_CORRECT
         (always, BAM)   (if --kit_name)     (if --correct)
```

## Supported barcode kits

EXP-NBD103, EXP-NBD104, EXP-NBD114, EXP-NBD114-24, EXP-NBD196, EXP-PBC001, EXP-PBC096, SQK-16S024, SQK-16S114-24, SQK-LWB001, SQK-MLK111-96-XL, SQK-MLK114-96-XL, SQK-NBD111-24, SQK-NBD111-96, SQK-NBD114-24, SQK-NBD114-96, SQK-PBK004, SQK-PCB109, SQK-PCB110, SQK-PCB111-24, SQK-PCB114-24, SQK-RBK001, SQK-RBK004, SQK-RBK110-96, SQK-RBK111-24, SQK-RBK111-96, SQK-RBK114-24, SQK-RBK114-96, SQK-RLB001, SQK-RPB004, SQK-RPB114-24, TWIST-16-UDI, TWIST-96A-UDI, VSK-PTC001, VSK-VMK001, VSK-VMK004, VSK-VPS001

## Supported modification models

| Model | Detects |
|-------|---------|
| `5mCG_5hmCG` | 5-methylcytosine and 5-hydroxymethylcytosine at CpG motifs |
| `5mCG` | 5-methylcytosine at CpG motifs |
| `5mC_5hmC` | 5-methylcytosine and 5-hydroxymethylcytosine (all context) |
| `5mC` | 5-methylcytosine (all context) |
| `5hmCG` | 5-hydroxymethylcytosine at CpG motifs |
| `6mA` | N6-methyladenine |

Multiple models can be combined: `--modified_bases 5mCG_5hmCG,6mA`
