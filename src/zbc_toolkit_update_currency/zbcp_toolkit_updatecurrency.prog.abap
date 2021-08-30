*&---------------------------------------------------------------------*
*& Report ZSDP_TOOLKIT_DENEME
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zbcp_toolkit_updatecurrency.

DATA: messages TYPE REF TO if_reca_message_list.

TRY.
    DATA(currency_lists) = NEW zcl_bc_toolkit_updatecurrency( )->get_tcurr( ).
    IF currency_lists IS INITIAL.
      WRITE: / text-001.
      MESSAGE e000(zbc).
    ELSE.
      MODIFY tcurr FROM TABLE currency_lists.
      COMMIT WORK AND WAIT.
      WRITE: / |{ sy-datum } { sy-uzeit } { text-002 } |.
      LOOP AT currency_lists REFERENCE INTO DATA(currency_list).
        WRITE: / | { currency_list->kurst } { currency_list->fcurr } { currency_list->tcurr } { currency_list->gdatu } { currency_list->ukurs } { currency_list->ffact } { currency_list->tfact } |.
      ENDLOOP.
    ENDIF.
  CATCH zcx_bc_toolkit_updatecurrency INTO DATA(exceptions).
    messages ?= exceptions->messages.
    messages->get_list_as_bapiret( IMPORTING et_list = DATA(message_list) ).
    LOOP AT message_list REFERENCE INTO DATA(message).
      WRITE: / | { message->type } { message->id } { message->number } { message->message } { message->message_v1 } { message->message_v2 } { message->message_v3 } { message->message_v4 } |.
    ENDLOOP.
    MESSAGE e000(zbc).
ENDTRY.
