.equ sbi_base_eid, 0x10

.equ sbi_get_sbi_spec_version_fid, 0
.equ sbi_get_sbi_impl_id_fid, 1
.equ sbi_get_sbi_impl_version_fid, 2

.section .text.sbi

.globl sbi_get_spec_version
.globl sbi_get_impl_id
.globl sbi_get_impl_version

# a7 encodes the SBI extension ID (EID)
# a6 encodes the SBI function ID (FID)
# SBI functions must return a pair of values in a0 and a1, with a0 returning an error code.

sbi_get_spec_version:
    li      a7, sbi_base_eid
    li      a6, sbi_get_sbi_spec_version_fid
    ecall
    mv      a0, a1
    ret

sbi_get_impl_id:
    li      a7, sbi_base_eid
    li      a6, sbi_get_sbi_impl_id_fid
    ecall
    mv      a0, a1
    ret

sbi_get_impl_version:
    li      a7, sbi_base_eid
    li      a6, sbi_get_sbi_impl_version_fid
    ecall
    mv      a0, a1
    ret
