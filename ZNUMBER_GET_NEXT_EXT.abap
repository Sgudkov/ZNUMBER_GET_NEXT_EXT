*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(NR_RANGE_NR) LIKE  INRI-NRRANGENR
*"     VALUE(OBJECT) LIKE  INRI-OBJECT
*"     VALUE(SUBOBJECT)
*"     VALUE(TOYEAR) LIKE  INRI-TOYEAR DEFAULT '0000'
*"  EXPORTING
*"     VALUE(NUMBER)
*"  EXCEPTIONS
*"      INTERVAL_NOT_FOUND
*"      OBJECT_NOT_FOUND
*"      INTERVAL_OVERFLOW
*"      NUMBER_RANGE_NOT_EXTERN
*"      EXTERNAL_OVERFLOW
*"      UPDATE_ERROR
*"----------------------------------------------------------------------

  SELECT SINGLE * FROM tnro INTO @DATA(ls_tnro)
         WHERE object = @object.
  IF sy-subrc <> 0.
    MESSAGE e002 WITH object RAISING object_not_found.
  ENDIF.

  SELECT SINGLE FOR UPDATE *
    INTO @DATA(ls_nriv)
    FROM nriv
    WHERE object    = @object
      AND subobject = @subobject
      AND nrrangenr = @nr_range_nr
      AND toyear    = @toyear.
  IF sy-subrc <> 0.
    MESSAGE e751 RAISING interval_not_found
                 WITH    object subobject nr_range_nr toyear.
  ENDIF.

  IF ls_nriv-externind = space.
    MESSAGE e753 RAISING number_range_not_extern.
  ENDIF.

  IF ls_nriv-fromnumber IS INITIAL OR ls_nriv-tonumber IS INITIAL.
    MESSAGE e751 RAISING interval_not_found
            WITH ls_nriv-object    ls_nriv-subobject
                 ls_nriv-nrrangenr ls_nriv-toyear.
  ENDIF.

  IF ls_nriv-nrlevel IS INITIAL.
    ls_nriv-nrlevel = ls_nriv-fromnumber.
  ELSE.
    ls_nriv-nrlevel += 1.
  ENDIF.

  IF ls_nriv-nrlevel > ls_nriv-tonumber.
    MESSAGE e028 RAISING external_overflow
                 WITH    ls_nriv-fromnumber
                         ls_nriv-tonumber
                         ls_nriv-object.
  ENDIF.

  UPDATE nriv SET nrlevel = ls_nriv-nrlevel
    WHERE object    = object
      AND subobject = subobject
      AND nrrangenr = nr_range_nr
      AND toyear    = toyear.
  IF sy-subrc = 0.
    COMMIT WORK.
  ELSE.
    ROLLBACK WORK.
    MESSAGE e009 RAISING update_error.
  ENDIF.

  number = ls_nriv-nrlevel.
