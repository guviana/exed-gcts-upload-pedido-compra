CLASS zexed_bp_i_up_pdcmp DEFINITION
PUBLIC
ABSTRACT
FINAL
FOR BEHAVIOR OF zexed_i_up_pdcmp.

  PUBLIC SECTION.
    CONSTANTS c_msg_none                    TYPE string VALUE `Nenhum arquivo selecionado`.
    CONSTANTS c_msg_ready                   TYPE string VALUE `Arquivo pronto`.
    CONSTANTS c_msg_uploaded                TYPE string VALUE `Excel carregado`.
    CONSTANTS c_msg_error                   TYPE string VALUE `Template com erro`.
    CONSTANTS c_msg_status_not_published    TYPE string VALUE `Não publicado`.
    CONSTANTS c_msg_status_published        TYPE string VALUE `Publicado`.
    CONSTANTS c_msg_status_error            TYPE string VALUE `Erro`.