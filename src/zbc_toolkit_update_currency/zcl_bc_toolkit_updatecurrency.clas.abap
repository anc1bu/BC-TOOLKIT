CLASS zcl_bc_toolkit_updatecurrency DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES:
    tt_tcurr TYPE TABLE OF tcurr WITH EMPTY KEY .
    METHODS constructor
      RAISING
        zcx_bc_toolkit_updatecurrency .
    METHODS get_tcurr
      RETURNING
        VALUE(tcurr) TYPE tt_tcurr
      RAISING
        zcx_bc_toolkit_updatecurrency .
  PRIVATE SECTION.
    TYPES:
      BEGIN OF currency_item,
        kod           TYPE string,
        currency_item TYPE REF TO if_ixml_node,
      END OF currency_item,
      currency_items TYPE STANDARD TABLE OF currency_item WITH EMPTY KEY,
      BEGIN OF deserialized_currency_item,
        kod   TYPE string,
        name  TYPE string,
        value TYPE string,
      END OF deserialized_currency_item,
      deserialized_currency_items TYPE STANDARD TABLE OF  deserialized_currency_item WITH EMPTY KEY.

    DATA:
      document   TYPE REF TO if_ixml_document,
      tarih_date TYPE REF TO if_ixml_element,
      messages   TYPE REF TO if_reca_message_list.

    CONSTANTS:
      url           TYPE string VALUE 'https://www.tcmb.gov.tr/kurlar/today.xml' ##NO_TEXT,
      currency_TRY  TYPE waers VALUE 'TRY',
      forex_buying  TYPE kurst VALUE 'M',
      forex_selling TYPE kurst VALUE 'B'.

    CLASS-METHODS get_value_from_iteration
      IMPORTING
        !name        TYPE string
        !iterator    TYPE REF TO if_ixml_node_iterator
      RETURNING
        VALUE(value) TYPE string
      RAISING
        zcx_bc_toolkit_updatecurrency .
    CLASS-METHODS get_name_value_from_iteration
      IMPORTING
        !iterator                          TYPE REF TO if_ixml_node_iterator
        !kod                               TYPE string
      RETURNING
        VALUE(deserialized_currency_items) TYPE deserialized_currency_items
      RAISING
        zcx_bc_toolkit_updatecurrency .
    CLASS-METHODS get_currency_items
      IMPORTING
        !tarih_date           TYPE REF TO if_ixml_element
      RETURNING
        VALUE(currency_items) TYPE currency_items
      RAISING
        zcx_bc_toolkit_updatecurrency .
ENDCLASS.

CLASS zcl_bc_toolkit_updatecurrency IMPLEMENTATION.
  METHOD constructor.

    me->messages = cf_reca_message_list=>create( ).

    cl_http_client=>create_by_url(
      EXPORTING
        url                    = me->url
      IMPORTING
        client                 = DATA(client)
      EXCEPTIONS
        argument_not_found     = 1
        plugin_not_active      = 2
        internal_error         = 3
        pse_not_found          = 4
        pse_not_distrib        = 5
        pse_errors             = 6
        OTHERS                 = 7 ).
    IF sy-subrc <> 0.
      me->messages->add(
        EXPORTING
          id_msgty         = sy-msgty
          id_msgid         = sy-msgid
          id_msgno         = sy-msgno
          id_msgv1         = sy-msgv1
          id_msgv2         = sy-msgv2
          id_msgv3         = sy-msgv3
          id_msgv4         = sy-msgv4 ).
    ENDIF.

    client->send( ).
    IF sy-subrc IS NOT INITIAL.
      me->messages->add(
        EXPORTING
          id_msgty         = sy-msgty
          id_msgid         = sy-msgid
          id_msgno         = sy-msgno
          id_msgv1         = sy-msgv1
          id_msgv2         = sy-msgv2
          id_msgv3         = sy-msgv3
          id_msgv4         = sy-msgv4 ).
    ENDIF.

    client->receive( ).
    IF sy-subrc IS NOT INITIAL.
      me->messages->add(
        EXPORTING
          id_msgty         = sy-msgty
          id_msgid         = sy-msgid
          id_msgno         = sy-msgno
          id_msgv1         = sy-msgv1
          id_msgv2         = sy-msgv2
          id_msgv3         = sy-msgv3
          id_msgv4         = sy-msgv4 ).
    ENDIF.

    DATA(ixml) = cl_ixml=>create( ).
    DATA(stream_factory) = ixml->create_stream_factory( ).
    document      = ixml->create_document( ).
    IF ixml->create_parser( stream_factory = stream_factory
                            istream        = stream_factory->create_istream_cstring( client->response->get_cdata( ) )
                            document       = document )->parse( ) NE ixml_mr_parser_ok.
      me->messages->add(
        EXPORTING
          id_msgty         = sy-msgty
          id_msgid         = sy-msgid
          id_msgno         = sy-msgno
          id_msgv1         = sy-msgv1
          id_msgv2         = sy-msgv2
          id_msgv3         = sy-msgv3
          id_msgv4         = sy-msgv4 ).
    ENDIF.

    tarih_date = document->get_root_element( ).

    IF messages->is_empty( ) EQ abap_false.
      RAISE EXCEPTION TYPE zcx_bc_toolkit_updatecurrency
        EXPORTING
          messages = messages.
    ENDIF.

  ENDMETHOD.

  METHOD get_tcurr.

    DATA: deserialized_currency_items TYPE deserialized_currency_items,
          date_internal               TYPE gdatu_inv.

    LOOP AT  get_currency_items( tarih_date ) ASSIGNING FIELD-SYMBOL(<currency_item>).
      INSERT LINES OF get_name_value_from_iteration( kod      = <currency_item>-kod
                                                     iterator = <currency_item>-currency_item->get_children( )->create_iterator( ) ) INTO TABLE deserialized_currency_items.
    ENDLOOP.

    CALL FUNCTION 'CONVERSION_EXIT_INVDT_INPUT'
      EXPORTING
        input  = tarih_date->get_attribute_ns( name = 'Tarih' )
      IMPORTING
        output = date_internal.

    LOOP AT deserialized_currency_items ASSIGNING FIELD-SYMBOL(<deserialized_currency_item>)
      WHERE name EQ 'ForexBuying'
         OR name EQ 'ForexSelling' .

      INSERT VALUE #( kurst = COND #( WHEN <deserialized_currency_item>-name EQ 'ForexBuying'
                                      THEN forex_buying
                                      WHEN <deserialized_currency_item>-name EQ 'ForexSelling'
                                      THEN forex_selling )
                      fcurr = <deserialized_currency_item>-kod
                      tcurr = currency_TRY
                      gdatu = date_internal
                      ukurs = <deserialized_currency_item>-value
                      ffact = 1
                      tfact = 1 ) INTO TABLE tcurr.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_value_from_iteration.

    DO.
      DATA(node) = iterator->get_next( ).
      IF node IS INITIAL.
        EXIT.
      ENDIF.
      IF node->get_name( ) = name .
        value = node->get_value(  ).
      ENDIF.
    ENDDO.

  ENDMETHOD.

  METHOD get_name_value_from_iteration.

    DO.
      DATA(node) = iterator->get_next( ).
      IF node IS INITIAL.
        EXIT.
      ENDIF.
      DATA(name)  = node->get_name( ).
      DATA(value) = node->get_value( ).

      INSERT VALUE #( kod   = kod
                      name  = name
                      value = value ) INTO TABLE deserialized_currency_items.


    ENDDO.

  ENDMETHOD.

  METHOD get_currency_items.

    DATA(Currency) = Tarih_Date->get_children( ).

    DO Currency->get_length( ) TIMES.
      DATA(currency_Item) = Currency->get_item( sy-index - 1 ).
      get_value_from_iteration(
        EXPORTING
          name     = 'Kod'
          iterator = currency_Item->get_attributes( )->create_iterator( )
        RECEIVING
          value    = DATA(kod) ).

      INSERT VALUE #( kod           =  kod
                      currency_item =  currency_item ) INTO TABLE currency_items.
    ENDDO.

  ENDMETHOD.

ENDCLASS.
