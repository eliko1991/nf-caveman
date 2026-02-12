#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-caveman
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    A Nextflow pipeline for running CaVEMan somatic SNV calling
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GitHub : https://github.com/papaemmelab/nf-caveman
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CAVEMAN_SETUP        } from './modules/local/caveman_setup'
include { CAVEMAN_SPLIT        } from './modules/local/caveman_split'
include { REMOVE_CONTIGS       } from './modules/local/remove_contigs'
include { CAVEMAN_SPLIT_CONCAT } from './modules/local/caveman_split_concat'
include { CAVEMAN_MSTEP        } from './modules/local/caveman_mstep'
include { CAVEMAN_MERGE        } from './modules/local/caveman_merge'
include { CAVEMAN_ESTEP        } from './modules/local/caveman_estep'
include { CAVEMAN_MERGE_RESULTS} from './modules/local/caveman_merge_results'
include { CAVEMAN_ADD_IDS      } from './modules/local/caveman_add_ids'
include { CAVEMAN_FLAG         } from './modules/local/caveman_flag'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOW FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CAVEMAN {

    // Validate inputs
    if (!params.tumour_bam) { exit 1, "Tumour BAM file not specified. Use --tumour_bam" }
    if (!params.normal_bam) { exit 1, "Normal BAM file not specified. Use --normal_bam" }
    if (!params.reference)  { exit 1, "Reference FAI file not specified. Use --reference" }

    // Create input channels
    ch_tumour_bam = Channel.fromPath(params.tumour_bam, checkIfExists: true)
        .map { bam ->
            def bai = file("${bam}.bai")
            if (!bai.exists()) { exit 1, "BAM index not found: ${bai}" }
            tuple(bam, bai)
        }

    ch_normal_bam = Channel.fromPath(params.normal_bam, checkIfExists: true)
        .map { bam ->
            def bai = file("${bam}.bai")
            if (!bai.exists()) { exit 1, "BAM index not found: ${bai}" }
            tuple(bam, bai)
        }

    ch_reference = Channel.fromPath(params.reference, checkIfExists: true)
        .map { fai ->
            def fa = file(fai.toString().replaceAll(/\.fai$/, ''))
            if (!fa.exists()) { exit 1, "Reference FASTA not found: ${fa}" }
            tuple(fa, fai)
        }

    // Optional inputs - use unique placeholders for empty optional inputs to avoid file name collisions
    ch_normal_cn  = params.normal_cn   ? Channel.fromPath(params.normal_cn, checkIfExists: true)   : Channel.value(file('NO_FILE_NORMAL_CN'))
    ch_tumour_cn  = params.tumour_cn   ? Channel.fromPath(params.tumour_cn, checkIfExists: true)   : Channel.value(file('NO_FILE_TUMOUR_CN'))
    ch_ignore     = params.ignore_file ? Channel.fromPath(params.ignore_file, checkIfExists: true) : Channel.value(file('NO_FILE_IGNORE'))
    ch_annot_bed  = params.annot_bed_files ? Channel.fromPath(params.annot_bed_files, checkIfExists: true) : Channel.value(file('NO_FILE_ANNOT'))
    ch_flag_bed   = params.flag_bed_files ? Channel.fromPath(params.flag_bed_files, checkIfExists: true) : Channel.value(file('NO_FILE_FLAG_BED'))
    ch_germline   = params.germline_indel ? Channel.fromPath(params.germline_indel, checkIfExists: true) : Channel.value(file('NO_FILE_GERMLINE'))
    ch_unmatched  = params.unmatched_vcf ? Channel.fromPath(params.unmatched_vcf, checkIfExists: true) : Channel.value(file('NO_FILE_UNMATCHED'))
    ch_flag_config = params.flagConfig ? Channel.fromPath(params.flagConfig, checkIfExists: true) : Channel.value(file('NO_FILE_FLAG_CONFIG'))
    ch_flag_to_vcf = params.flagToVcfConfig ? Channel.fromPath(params.flagToVcfConfig, checkIfExists: true) : Channel.value(file('NO_FILE_FLAG_TO_VCF'))

    // Combine BAM inputs
    ch_bams = ch_tumour_bam.combine(ch_normal_bam)

    // Combine all inputs for caveman processes
    // Format: tumour_bam, tumour_bai, normal_bam, normal_bai, reference_fa, reference_fai, normal_cn, tumour_cn, ignore_file
    ch_inputs = ch_bams
        .combine(ch_reference)
        .combine(ch_normal_cn)
        .combine(ch_tumour_cn)
        .combine(ch_ignore)

    // Create a channel with just the files needed for all steps (without reference_fa)
    // Format: tumour_bam, tumour_bai, normal_bam, normal_bai, reference_fai, normal_cn, tumour_cn, ignore_file
    ch_common_inputs = ch_bams
        .combine(ch_reference.map { fa, fai -> fai })
        .combine(ch_normal_cn)
        .combine(ch_tumour_cn)
        .combine(ch_ignore)

    //
    // STEP 1: Setup CaVEMan
    //
    CAVEMAN_SETUP(ch_inputs)

    //
    // STEP 2: Split genome into chunks (parallel by reference contig)
    //
    CAVEMAN_SPLIT(
        CAVEMAN_SETUP.out.workdir,
        ch_common_inputs
    )

    //
    // STEP 3: Remove unwanted contigs (GL, hs, MT, NC)
    //
    REMOVE_CONTIGS(CAVEMAN_SPLIT.out.workdir)

    //
    // STEP 4: Concatenate split files
    //
    // Combine workdir with common inputs
    ch_split_concat_input = REMOVE_CONTIGS.out.workdir
        .combine(ch_common_inputs)

    CAVEMAN_SPLIT_CONCAT(ch_split_concat_input)

    //
    // STEP 5: M-step (parallel by split index)
    //
    // Get the number of splits and create index channel
    ch_mstep_indices = CAVEMAN_SPLIT_CONCAT.out.workdir
        .combine(ch_common_inputs)
        .map { workdir, tumour_bam, tumour_bai, normal_bam, normal_bai, reference_fai, normal_cn, tumour_cn, ignore_file ->
            def splitList = file("${workdir}/tmpCaveman/splitList")
            def count = splitList.readLines().findAll { it.trim() }.size()
            (1..count).collect { idx -> 
                tuple(workdir, idx, tumour_bam, tumour_bai, normal_bam, normal_bai, reference_fai, normal_cn, tumour_cn, ignore_file) 
            }
        }
        .flatMap { it }

    CAVEMAN_MSTEP(ch_mstep_indices)

    //
    // STEP 6: Merge M-step results
    //
    ch_mstep_done = CAVEMAN_MSTEP.out.done.collect()
    ch_merge_input = CAVEMAN_SPLIT_CONCAT.out.workdir
        .combine(ch_common_inputs)
        .combine(ch_mstep_done.map { 'done' })
        .map { workdir, tumour_bam, tumour_bai, normal_bam, normal_bai, reference_fai, normal_cn, tumour_cn, ignore_file, done ->
            tuple(workdir, tumour_bam, tumour_bai, normal_bam, normal_bai, reference_fai, normal_cn, tumour_cn, ignore_file)
        }

    CAVEMAN_MERGE(ch_merge_input)

    //
    // STEP 7: E-step (parallel by split index)
    //
    ch_estep_indices = CAVEMAN_MERGE.out.workdir
        .combine(ch_common_inputs)
        .map { workdir, tumour_bam, tumour_bai, normal_bam, normal_bai, reference_fai, normal_cn, tumour_cn, ignore_file ->
            def splitList = file("${workdir}/tmpCaveman/splitList")
            def count = splitList.readLines().findAll { it.trim() }.size()
            (1..count).collect { idx -> 
                tuple(workdir, idx, tumour_bam, tumour_bai, normal_bam, normal_bai, reference_fai, normal_cn, tumour_cn, ignore_file) 
            }
        }
        .flatMap { it }

    CAVEMAN_ESTEP(ch_estep_indices)

    //
    // STEP 8: Merge E-step results
    //
    ch_estep_done = CAVEMAN_ESTEP.out.done.collect()
    ch_results_input = CAVEMAN_MERGE.out.workdir
        .combine(ch_common_inputs)
        .combine(ch_estep_done.map { 'done' })
        .map { workdir, tumour_bam, tumour_bai, normal_bam, normal_bai, reference_fai, normal_cn, tumour_cn, ignore_file, done ->
            tuple(workdir, tumour_bam, tumour_bai, normal_bam, normal_bai, reference_fai, normal_cn, tumour_cn, ignore_file)
        }

    CAVEMAN_MERGE_RESULTS(ch_results_input)

    //
    // STEP 9: Add IDs to VCF
    //
    ch_add_ids_input = CAVEMAN_MERGE_RESULTS.out.workdir
        .combine(ch_common_inputs)

    CAVEMAN_ADD_IDS(ch_add_ids_input)

    //
    // STEP 10: Flag variants (optional)
    //
    if (params.flag_bed_files && params.germline_indel && params.unmatched_vcf) {
        ch_flag_inputs = CAVEMAN_ADD_IDS.out.vcf
            .combine(ch_tumour_bam)
            .combine(ch_normal_bam)
            .combine(ch_reference)
            .combine(ch_flag_bed)
            .combine(ch_germline)
            .combine(ch_unmatched)
            .combine(ch_annot_bed)
            .combine(ch_flag_config)
            .combine(ch_flag_to_vcf)

        CAVEMAN_FLAG(ch_flag_inputs)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {
    CAVEMAN()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
