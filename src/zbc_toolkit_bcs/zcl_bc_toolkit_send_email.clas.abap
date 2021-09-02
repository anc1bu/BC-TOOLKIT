CLASS zcl_bc_toolkit_send_email DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      bcs      TYPE REF TO cl_bcs,
      messages TYPE REF TO if_reca_message_list.
    METHODS:
      constructor
        IMPORTING
          recipient_address TYPE ad_smtpadr
          sender            TYPE syst_uname OPTIONAL
        RAISING
          zcx_bc_toolkit_send_email
          cx_send_req_bcs
          cx_address_bcs
          cx_document_bcs,
      send_simple_text
        IMPORTING
                  body_text     TYPE string
                  subject       TYPE so_obj_des
        RETURNING VALUE(result) TYPE abap_bool.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_bc_toolkit_send_email IMPLEMENTATION.
  METHOD constructor.

    me->messages = cf_reca_message_list=>create( ).

    me->bcs = cl_bcs=>create_persistent( ).

    me->bcs->set_sender( cl_sapuser_bcs=>create( COND #( WHEN sender IS INITIAL
                                                         THEN sy-uname
                                                         ELSE sender ) ) ).

    me->bcs->add_recipient( cl_cam_address_bcs=>create_internet_address( recipient_address ) ).

  ENDMETHOD.

  METHOD send_simple_text.
    TRY.
        me->bcs->set_document( cl_document_bcs=>create_from_text( i_text = cl_document_bcs=>string_to_soli( body_text )
                                                                  i_subject = subject ) ).

        result = me->bcs->send( ).
        COMMIT WORK.
      CATCH cx_bcs INTO DATA(exc).
        ROLLBACK WORK.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
