dnl/*
dnl * Copyright (c) 2006 The Trustees of Indiana University and Indiana
dnl *                    University Research and Technology
dnl *                    Corporation.  All rights reserved.
dnl * Copyright (c) 2006 The Technical University of Chemnitz. All 
dnl *                    rights reserved.
dnl */
dnl
dnl this m4 code generate all MPI intrinsic operations
dnl every macro is prefixed with m4_ to retain clarity (this means that
dnl everything prefixed with m4_ will be replaced by m4!)
dnl
dnl 
dnl
dnl ########## define all MPI intrinsic Operations and appropriate C code #############
define(m4_OP_MPI_MIN, `if(m4_ARG1$1 > m4_ARG2$1) m4_ARG3$1 = m4_ARG2$1; else m4_ARG3$1 = m4_ARG1$1;')dnl
define(m4_OP_MPI_MAX, `if(m4_ARG1$1 < m4_ARG2$1) m4_ARG3$1 = m4_ARG2$1; else m4_ARG3$1 = m4_ARG1$1;')dnl
define(m4_OP_MPI_SUM, `m4_ARG3$1 = m4_ARG1$1 + m4_ARG2$1;')dnl
define(m4_OP_MPI_PROD, `m4_ARG3$1 = m4_ARG1$1 * m4_ARG2$1;')dnl
define(m4_OP_MPI_LAND, `m4_ARG3$1 = m4_ARG1$1 && m4_ARG2$1;')dnl
define(m4_OP_MPI_BAND, `m4_ARG3$1 = m4_ARG1$1 & m4_ARG2$1;')dnl
define(m4_OP_MPI_LOR, `m4_ARG3$1 = m4_ARG1$1 || m4_ARG2$1;')dnl
define(m4_OP_MPI_BOR, `m4_ARG3$1 = m4_ARG1$1 | m4_ARG2$1;')dnl
define(m4_OP_MPI_LXOR, `m4_ARG3$1 = ((m4_ARG1$1 ? 1 : 0) ^ (m4_ARG2$1 ?  1 : 0));')dnl
define(m4_OP_MPI_BXOR, `m4_ARG3$1 = ((m4_ARG1$1) ^ (m4_ARG2$1));')dnl
define(m4_OP_MPI_MINLOC, `if(m4_ARG1$1_VAL > m4_ARG2$1_VAL) { 
          m4_ARG3$1_VAL = m4_ARG2$1_VAL; m4_ARG3$1_RANK = m4_ARG2$1_RANK; 
        } else { 
          m4_ARG3$1_VAL = m4_ARG1$1_VAL; m4_ARG3$1_RANK = m4_ARG1$1_RANK; 
        }')dnl
define(m4_OP_MPI_MAXLOC, `if(m4_ARG1$1_VAL < m4_ARG2$1_VAL) { 
          m4_ARG3$1_VAL = m4_ARG2$1_VAL; m4_ARG3$1_RANK = m4_ARG2$1_RANK; 
        } else { 
          m4_ARG3$1_VAL = m4_ARG1$1_VAL; m4_ARG3$1_RANK = m4_ARG1$1_RANK; 
        }')dnl
dnl 
dnl ########## define helper macros #################
dnl ########## loop-unrolled version -> slows it down :-( ######
dnl define(m4_IF, `if(op == $1) {
dnl       /* loop unrolling - 4 */
dnl       for(i=0; i<count-3; i=i+4) {
dnl         m4_CTYPE_$2 val11, val12, val21, val22, val31, val32, val41, val42;
dnl 
dnl         val11 = *(((m4_CTYPE_$2*)buf1) + i);
dnl         val12 = *(((m4_CTYPE_$2*)buf2) + i);
dnl         val21 = *(((m4_CTYPE_$2*)buf1) + i+1);
dnl         val22 = *(((m4_CTYPE_$2*)buf2) + i+1);
dnl         val31 = *(((m4_CTYPE_$2*)buf1) + i+2);
dnl         val32 = *(((m4_CTYPE_$2*)buf2) + i+2);
dnl         val41 = *(((m4_CTYPE_$2*)buf1) + i+3);
dnl         val42 = *(((m4_CTYPE_$2*)buf2) + i+3);
dnl       
dnl define(m4_ARG11_$1$2, val11)dnl
dnl define(m4_ARG21_$1$2, val12)dnl
dnl define(m4_ARG31_$1$2, val11)dnl
dnl         m4_OP_$1(1_$1$2) 
dnl define(m4_ARG12_$1$2, val21)dnl
dnl define(m4_ARG22_$1$2, val22)dnl
dnl define(m4_ARG32_$1$2, val21)dnl
dnl         m4_OP_$1(2_$1$2)
dnl define(m4_ARG13_$1$2, val31)dnl
dnl define(m4_ARG23_$1$2, val32)dnl
dnl define(m4_ARG33_$1$2, val31)dnl
dnl         m4_OP_$1(3_$1$2)
dnl define(m4_ARG14_$1$2, val41)dnl
dnl define(m4_ARG24_$1$2, val42)dnl
dnl define(m4_ARG34_$1$2, val41)dnl
dnl         m4_OP_$1(4_$1$2)
dnl 
dnl         *(((m4_CTYPE_$2*)buf3) + i) = val11;
dnl         *(((m4_CTYPE_$2*)buf3) + i+1) = val21;
dnl         *(((m4_CTYPE_$2*)buf3) + i+2) = val31;
dnl         *(((m4_CTYPE_$2*)buf3) + i+3) = val41;
dnl       }
dnl       for(i=i+4;i<count;i++) {
dnl         m4_CTYPE_$2 val11, val12;
dnl 
dnl         val11 = *(((m4_CTYPE_$2*)buf1) + i);
dnl         val12 = *(((m4_CTYPE_$2*)buf2) + i);
dnl         
dnl define(m4_ARG15_$1$2, val11)dnl
dnl define(m4_ARG25_$1$2, val12)dnl
dnl define(m4_ARG35_$1$2, val11)dnl
dnl         m4_OP_$1(5_$1$2)
dnl         
dnl         *(((m4_CTYPE_$2*)buf3) + i) = val11;
dnl       }
dnl     }')dnl
dnl ########################################################## 
dnl ########### THIS is faster as the unrolled code :-(( #####
define(m4_IF, `if(op == $1) {
      for(i=0; i<count; i++) {
define(m4_ARG1_$2, `*(((m4_CTYPE_$2*)buf1) + i)')dnl
define(m4_ARG2_$2, `*(((m4_CTYPE_$2*)buf2) + i)')dnl
define(m4_ARG3_$2, `*(((m4_CTYPE_$2*)buf3) + i)')dnl
        m4_OP_$1(_$2) 
      }
    }')dnl
dnl ############################################### MINLOC and MAXLOC
define(m4_LOCIF, `if(op == $1) {
      for(i=0; i<count; i++) {
        typedef struct {
          m4_CTYPE1_$2 val;
          m4_CTYPE2_$2 rank;
        } m4_CTYPE3_$2;
        m4_CTYPE3_$2 *ptr1, *ptr2, *ptr3;
                            
        ptr1 = ((m4_CTYPE3_$2*)buf1) + i;
        ptr2 = ((m4_CTYPE3_$2*)buf2) + i;
        ptr3 = ((m4_CTYPE3_$2*)buf3) + i;
      
define(m4_ARG1_VAL, ptr1->val)dnl
define(m4_ARG2_VAL, ptr2->val)dnl
define(m4_ARG3_VAL, ptr3->val)dnl
define(m4_ARG1_RANK, ptr1->rank)dnl
define(m4_ARG2_RANK, ptr2->rank)dnl
define(m4_ARG3_RANK, ptr3->rank)dnl
        m4_OP_$1 
      }  
    }')dnl
dnl ############################################### complex numbers MPI_SUM (Fortran only)
define(m4_COMPSUMIF, `if(op == MPI_SUM) {
      for(i=0; i<count; i++) {
        typedef struct {
          m4_CTYPE1_$1 real;
          m4_CTYPE1_$1 imag;
        } m4_CTYPE2_$1;
        m4_CTYPE2_$1 *ptr1, *ptr2, *ptr3;
                            
        ptr1 = ((m4_CTYPE2_$1*)buf1) + i;
        ptr2 = ((m4_CTYPE2_$1*)buf2) + i;
        ptr3 = ((m4_CTYPE2_$1*)buf3) + i;

        ptr3->real = ptr2->real + ptr1->real; 
        ptr3->imag = ptr2->imag + ptr1->imag; 
      }  
  }')dnl
dnl ############################################### complex numbers MPI_PROD (Fortran only)
define(m4_COMPPRODIF, `if(op == MPI_PROD) {
      for(i=0; i<count; i++) {
        typedef struct {
          m4_CTYPE1_$1 real;
          m4_CTYPE1_$1 imag;
        } m4_CTYPE2_$1;
        m4_CTYPE2_$1 *ptr1, *ptr2, *ptr3;

        ptr1 = ((m4_CTYPE2_$1*)buf1) + i;
        ptr2 = ((m4_CTYPE2_$1*)buf2) + i;
        ptr3 = ((m4_CTYPE2_$1*)buf3) + i;

        ptr3->real = ptr1->real * ptr2->real - ptr1->imag * ptr2->imag; 
        ptr3->imag = ptr1->real * ptr2->imag + ptr1->imag * ptr2->real; 
      }  
  }')dnl
dnl ########################################################## 
define(m4_TYPE, `if(type == $1) { 
    m4_OPTYPE_$1($1) 
  }')dnl
dnl ########## define possible operations for each type 
dnl
dnl
dnl ####### MPI_INT ########
define(m4_OPTYPE_MPI_INT, `define(m4_CTYPE_$1, `int')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_INTEGER ########
define(m4_OPTYPE_MPI_INTEGER, `define(m4_CTYPE_$1, `int')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_LONG ########
define(m4_OPTYPE_MPI_LONG, `define(m4_CTYPE_$1, `long')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_LONG_LONG ########
define(m4_OPTYPE_MPI_LONG_LONG, `define(m4_CTYPE_$1, `long long')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_LONG_LONG_INT ########
define(m4_OPTYPE_MPI_LONG_LONG_INT, `define(m4_CTYPE_$1, `long long int')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_SHORT ########
define(m4_OPTYPE_MPI_SHORT, `define(m4_CTYPE_$1, `short')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_UNSIGNED ########
define(m4_OPTYPE_MPI_UNSIGNED, `define(m4_CTYPE_$1, `unsigned int')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_UNSIGNED_LONG ########
define(m4_OPTYPE_MPI_UNSIGNED_LONG, `define(m4_CTYPE_$1, `unsigned long')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_UNSIGNED_LONG_LONG ########
define(m4_OPTYPE_MPI_UNSIGNED_LONG_LONG, `define(m4_CTYPE_$1, `unsigned long long')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_UNSIGNED_SHORT ########
define(m4_OPTYPE_MPI_UNSIGNED_SHORT, `define(m4_CTYPE_$1, `unsigned short')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_INT8_T ########
define(m4_OPTYPE_MPI_INT8_T, `define(m4_CTYPE_$1, `int8_t')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_INT16_T ########
define(m4_OPTYPE_MPI_INT16_T, `define(m4_CTYPE_$1, `int16_t')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_INT32_T ########
define(m4_OPTYPE_MPI_INT32_T, `define(m4_CTYPE_$1, `int32_t')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_INT64_T ########
define(m4_OPTYPE_MPI_INT64_T, `define(m4_CTYPE_$1, `int64_t')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_UINT8_T ########
define(m4_OPTYPE_MPI_UINT8_T, `define(m4_CTYPE_$1, `uint8_t')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_UINT16_T ########
define(m4_OPTYPE_MPI_UINT16_T, `define(m4_CTYPE_$1, `uint16_t')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_UINT32_T ########
define(m4_OPTYPE_MPI_UINT32_T, `define(m4_CTYPE_$1, `uint32_t')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_UINT64_T ########
define(m4_OPTYPE_MPI_UINT64_T, `define(m4_CTYPE_$1, `uint64_t')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else m4_IF(MPI_LAND, $1) else dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_LXOR, $1) else m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_FLOAT ########
define(m4_OPTYPE_MPI_FLOAT, `define(m4_CTYPE_$1, `float')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_REAL ########
define(m4_OPTYPE_MPI_REAL, `define(m4_CTYPE_$1, `float')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_DOUBLE ########
define(m4_OPTYPE_MPI_DOUBLE, `define(m4_CTYPE_$1, `double')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_DOUBLE_PRECISION ########
define(m4_OPTYPE_MPI_DOUBLE_PRECISION, `define(m4_CTYPE_$1, `double')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_LONG_DOUBLE ########
define(m4_OPTYPE_MPI_LONG_DOUBLE, `define(m4_CTYPE_$1, `long double')dnl
m4_IF(MPI_MIN, $1) else m4_IF(MPI_MAX, $1) else dnl
m4_IF(MPI_SUM, $1) else m4_IF(MPI_PROD, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_BYTE ########
define(m4_OPTYPE_MPI_BYTE, `define(m4_CTYPE_$1, `char')dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_CHAR ########
define(m4_OPTYPE_MPI_CHAR, `define(m4_CTYPE_$1, `char')dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_SIGNED_CHAR ########
define(m4_OPTYPE_MPI_SIGNED_CHAR, `define(m4_CTYPE_$1, `signed char')dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_UNSIGNED_CHAR ########
define(m4_OPTYPE_MPI_UNSIGNED_CHAR, `define(m4_CTYPE_$1, `unsigned char')dnl
m4_IF(MPI_BAND, $1) else m4_IF(MPI_BOR, $1) else dnl
m4_IF(MPI_BXOR, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_COMPLEX ########
define(m4_OPTYPE_MPI_COMPLEX, `define(m4_CTYPE1_$1, `float')define(m4_CTYPE2_$1, `floatcplx')dnl
m4_COMPSUMIF($1) else m4_COMPPRODIF($1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_DOUBLE_COMPLEX ########
define(m4_OPTYPE_MPI_DOUBLE_COMPLEX, `define(m4_CTYPE1_$1, `double')define(m4_CTYPE2_$1, `doublecplx')dnl
m4_COMPSUMIF($1) else m4_COMPPRODIF($1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_LOGICAL ########
define(m4_OPTYPE_MPI_LOGICAL, `define(m4_CTYPE_$1, `char')dnl
m4_IF(MPI_LAND, $1) else m4_IF(MPI_LOR, $1) else m4_IF(MPI_LXOR, $1) MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_FLOAT_INT ########
define(m4_OPTYPE_MPI_FLOAT_INT, `define(m4_CTYPE1_$1, `float')define(m4_CTYPE2_$1, `int')define(m4_CTYPE3_$1, `float_int')dnl
m4_LOCIF(MPI_MAXLOC, $1) else m4_LOCIF(MPI_MINLOC, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_DOUBLE_INT ########
define(m4_OPTYPE_MPI_DOUBLE_INT, `define(m4_CTYPE1_$1, `double')define(m4_CTYPE2_$1, `int')define(m4_CTYPE3_$1, `double_int')dnl
m4_LOCIF(MPI_MAXLOC, $1) else m4_LOCIF(MPI_MINLOC, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_LONG_INT ########
define(m4_OPTYPE_MPI_LONG_INT, `define(m4_CTYPE1_$1, `long')define(m4_CTYPE2_$1, `int')define(m4_CTYPE3_$1, `long_int')dnl
m4_LOCIF(MPI_MAXLOC, $1) else m4_LOCIF(MPI_MINLOC, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_2INT ########
define(m4_OPTYPE_MPI_2INT, `define(m4_CTYPE1_$1, `int')define(m4_CTYPE2_$1, `int')define(m4_CTYPE3_$1, `int_int')dnl
m4_LOCIF(MPI_MAXLOC, $1) else m4_LOCIF(MPI_MINLOC, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_SHORT_INT ########
define(m4_OPTYPE_MPI_SHORT_INT, `define(m4_CTYPE1_$1, `short')define(m4_CTYPE2_$1, `int')define(m4_CTYPE3_$1, `short_int')dnl
m4_LOCIF(MPI_MAXLOC, $1) else m4_LOCIF(MPI_MINLOC, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### MPI_LONG_DOUBLE_INT ########
define(m4_OPTYPE_MPI_LONG_DOUBLE_INT, `define(m4_CTYPE1_$1, `long double')define(m4_CTYPE2_$1, `int')define(m4_CTYPE3_$1, `long_double_int')dnl
m4_LOCIF(MPI_MAXLOC, $1) else m4_LOCIF(MPI_MINLOC, $1) else MPI_Abort(MPI_COMM_WORLD, NBC_OP_NOT_SUPPORTED);')dnl
dnl
dnl ####### begin the real program :-) #########
dnl
/*
 * Copyright (c) 2006 The Trustees of Indiana University and Indiana
 *                    University Research and Technology
 *                    Corporation.  All rights reserved.
 * Copyright (c) 2006 The Technical University of Chemnitz. All 
 *                    rights reserved.
 *
 * Author(s): Torsten Hoefler <htor@cs.indiana.edu>
 *
 */
//#include "nbc.h"
#include <stdint.h>
#include <mpi.h>
 
/* Function return codes  */
#define NBC_OK 0 /* everything went fine */
#define NBC_SUCCESS 0 /* everything went fine (MPI compliant :) */
#define NBC_OOR 1 /* out of resources */
#define NBC_BAD_SCHED 2 /* bad schedule */
#define NBC_CONTINUE 3 /* progress not done */
#define NBC_DATATYPE_NOT_SUPPORTED 4 /* datatype not supported or not valid */
#define NBC_OP_NOT_SUPPORTED 5 /* operation not supported or not valid */
#define NBC_NOT_IMPLEMENTED 6
#define NBC_INVALID_PARAM 7 /* invalid parameters */
#define NBC_INVALID_TOPOLOGY_COMM 8 /* invalid topology attached to communicator */


/****************** THIS FILE is automatically generated *********************
 * changes will be deleted at the next generation of this file - see nbc_op.c.m4 */

int NBC_Operation(void *buf3, void *buf1, void *buf2, MPI_Op op, MPI_Datatype type, int count) {
  int i;
     
  m4_TYPE(MPI_INT) else dnl
dnl m4_TYPE(MPI_INTEGER) else dnl
m4_TYPE(MPI_LONG) else dnl
m4_TYPE(MPI_LONG_LONG) else dnl
m4_TYPE(MPI_LONG_LONG_INT) else dnl
m4_TYPE(MPI_SHORT) else dnl
m4_TYPE(MPI_UNSIGNED) else dnl
m4_TYPE(MPI_UNSIGNED_LONG) else dnl
m4_TYPE(MPI_UNSIGNED_LONG_LONG) else dnl
m4_TYPE(MPI_UNSIGNED_SHORT) else
#ifdef MPI_INT8_T
m4_TYPE(MPI_INT8_T) else
#endif
#ifdef MPI_INT16_T
m4_TYPE(MPI_INT16_T) else
#endif
#ifdef MPI_INT32_T
m4_TYPE(MPI_INT32_T) else
#endif
#ifdef MPI_INT64_T
m4_TYPE(MPI_INT64_T) else
#endif
#ifdef MPI_UINT8_T
m4_TYPE(MPI_UINT8_T) else
#endif
#ifdef MPI_UINT16_T
m4_TYPE(MPI_UINT16_T) else
#endif
#ifdef MPI_UINT32_T
m4_TYPE(MPI_UINT32_T) else
#endif
#ifdef MPI_UINT64_T
m4_TYPE(MPI_UINT64_T) else
#endif
m4_TYPE(MPI_FLOAT) else dnl
dnl m4_TYPE(MPI_REAL) else dnl
m4_TYPE(MPI_DOUBLE) else dnl
dnl m4_TYPE(MPI_DOUBLE_PRECISION) else dnl
m4_TYPE(MPI_LONG_DOUBLE) else dnl
m4_TYPE(MPI_BYTE) else dnl
m4_TYPE(MPI_CHAR) else dnl
m4_TYPE(MPI_SIGNED_CHAR) else dnl
m4_TYPE(MPI_UNSIGNED_CHAR) else dnl
dnl m4_TYPE(MPI_WCHAR) else dnl
dnl m4_TYPE(MPI_C_BOOL) else dnl
m4_TYPE(MPI_FLOAT_INT) else dnl
m4_TYPE(MPI_DOUBLE_INT) else dnl
m4_TYPE(MPI_LONG_INT) else dnl
m4_TYPE(MPI_2INT) else dnl
m4_TYPE(MPI_SHORT_INT) else dnl
m4_TYPE(MPI_LONG_DOUBLE_INT) else dnl
dnl m4_TYPE(MPI_C_COMPLEX) else dnl
dnl m4_TYPE(MPI_C_FLOAT_COMPLEX) else dnl
dnl m4_TYPE(MPI_C_DOUBLE_COMPLEX) else dnl
dnl m4_TYPE(MPI_C_LONG_DOUBLE_COMPLEX) else dnl
dnl m4_TYPE(MPI_LOGICAL) else dnl
dnl m4_TYPE(MPI_COMPLEX) else dnl
dnl m4_TYPE(MPI_DOUBLE_COMPLEX) else dnl
MPI_Abort(MPI_COMM_WORLD, NBC_DATATYPE_NOT_SUPPORTED);
dnl return NBC_DATATYPE_NOT_SUPPORTED;
  
  return NBC_OK;
}
