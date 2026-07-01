projection implementation in class ZEXED_BP_C_UP_PDCMP unique;
strict ( 2 );
extensible;
use draft;
use side effects;
define behavior for ZEXED_C_UP_PDCMP alias File
extensible
use etag
{
  use create;
  use update;
  use delete;

  use action Edit;
  use action Activate;
  use action Discard;
  use action Resume;
  use action Prepare;

  use association _PurchaseOrders { create; with draft; }
}

define behavior for ZEXED_C_UP_PDCMP_H alias PurchaseOrders
{
  use update;

  use association _File { with draft; }
  use association _Itens { create; with draft; }

  use action publish;
}

define behavior for ZEXED_C_UP_PDCMP_I alias PurchaseOrdersItem
{
  use update;

  use association _File { with draft; }
  use association _Header { with draft; }
  use association _AccAssignment { create; with draft; }
}

define behavior for ZEXED_C_UP_PDCMP_A alias PurchaseOrdersItemAccAss
{
  use update;

  use association _File { with draft; }
  use association _Item { with draft; }
}