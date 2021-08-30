CLASS zcx_bc_toolkit_currencyprocess DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_t100_message .

    CONSTANTS:
      BEGIN OF zcx_bc_toolkit_currencyprocess,
        msgid TYPE symsgid VALUE 'ZBC',
        msgno TYPE symsgno VALUE '000',
        attr1 TYPE scx_attrname VALUE 'MESSAGES',
        attr2 TYPE scx_attrname VALUE 'DISPLAY_LIKE',
        attr3 TYPE scx_attrname VALUE 'ERROR_TYPE',
        attr4 TYPE scx_attrname VALUE '',
      END OF zcx_bc_toolkit_currencyprocess .
    DATA messages TYPE REF TO if_reca_message_list .
    DATA error_type TYPE bapi_mtype .
    DATA display_like TYPE bapi_mtype .

    METHODS constructor
      IMPORTING
        !textid       LIKE if_t100_message=>t100key OPTIONAL
        !previous     LIKE previous OPTIONAL
        !error_type   TYPE bapi_mtype OPTIONAL
        !display_like TYPE bapi_mtype OPTIONAL
        !messages     TYPE REF TO if_reca_message_list OPTIONAL .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcx_bc_toolkit_currencyprocess IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.
    me->error_type = error_type .
    me->display_like = display_like .
    me->messages = messages .
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
