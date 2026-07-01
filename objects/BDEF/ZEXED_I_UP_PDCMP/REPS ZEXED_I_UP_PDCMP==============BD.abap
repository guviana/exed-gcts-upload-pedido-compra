managed implementation in class zexed_BP_I_UP_PDCMP unique;
strict ( 2 );
with draft;

define behavior for ZEXED_I_UP_PDCMP alias File
persistent table zexed_up_pdcmp
draft table zexed_up_pdcmp_d
lock master total etag LastChangedAt
authorization master ( global )
etag master LastChangedAt
with additional save
{
  create;
  update ( features : instance );
  delete;

  //=== Draft actions required when using strict (2) ===
  draft action Edit;
  draft action Resume;
  draft action Activate optimized;
  draft action Discard;

  //=== Draft determination required when using strict (2) ===
  draft determine action Prepare;

  determination validateTemplate on modify { field FileContent; }
  determination processFile on save { create; field FileContent; }

  field ( readonly ) LocalCreatedBy, LocalCreatedAt, LocalLastChangedBy, LocalLastChangedAt, LastChangedAt;

  field ( mandatory ) FileName, Mimetype;
  field ( numbering : managed, readonly ) UUID;

  side effects
  {

    field FileContent affects field FileStatus;

  }

  association _PurchaseOrders { create; with draft; }

  mapping for zexed_up_pdcmp
    {
      UUID               = uuid;
      FileName           = filename;
      FileSize           = file_size;
      FileStatus         = file_status;
      MimeType           = mimetype;
      FileContent        = file_content;
      LocalCreatedBy     = local_created_by;
      LocalCreatedAt     = local_created_at;
      LocalLastChangedBy = local_last_changed_by;
      LocalLastChangedAt = local_last_changed_at;
      LastChangedAt      = last_changed_at;
    }
}

define behavior for ZEXED_I_UP_PDCMP_H alias PurchaseOrder
persistent table zexed_up_pdcmp_h
draft table zexed_up_pdc_h_d
lock dependent by _File
authorization dependent by _File
etag master LastChangedAt
{
  update ( features : instance );
  internal delete;

  field ( numbering : managed, readonly ) UUID;

  field ( readonly ) ParentUUID;
  field ( readonly : update ) PurchaseOrder, Status;

  association _File { with draft; }
  association _Itens { create; with draft; }

  action ( features : instance ) publish result [0..*] $self;

  side effects
  {

    action publish affects field Status, field CriticalityStatus, field PurchaseOrder;

  }

  mapping for zexed_up_pdcmp_h
    {
      UUID                 = uuid;
      ParentUUID           = parent_uuid;
      PurchaseOrder        = purchase_order;
      Status               = status;
      CriticalityStatus    = criticalitystatus;
      PurchaseOrderType2   = purchase_order_type;
      PurchaseOrderDate    = purchase_order_date;
      CompanyCode          = company_code;
      PurchaseOrganization = purchase_org;
      PurchaseGroup        = purchase_grp;
      Supplier             = supplier;
      PaymentTerms         = payment_terms;
      LocalCreatedBy       = local_created_by;
      LocalCreatedAt       = local_created_at;
      LocalLastChangedBy   = local_last_changed_by;
      LocalLastChangedAt   = local_last_changed_at;
      LastChangedAt        = last_changed_at;
    }
}

define behavior for ZEXED_I_UP_PDCMP_I alias PurchaseOrderItem
persistent table zexed_up_pdcmp_i
draft table zexed_up_pdc_i_d
lock dependent by _File
authorization dependent by _File
etag master LastChangedAt
{
  update ( features : instance );
  internal delete;

  field ( numbering : managed, readonly ) UUID;

  field ( readonly ) FileUUID, ParentUUID;
  field ( readonly : update ) PurchaseOrder, Item;

  association _Header { with draft; }
  association _File { with draft; }
  association _AccAssignment { create; with draft; }

  mapping for zexed_up_pdcmp_i
    {
      UUID                           = uuid;
      ParentUUID                     = parent_uuid;
      FileUUID                       = file_uuid;
      PurchaseOrder                  = purchase_order;
      Item                           = item;
      Material                       = material;
      Plant                          = plant;
      DocumentCurrency               = document_currency;
      PurchaseOrderQuantityUnit      = purchase_order_quantity_unit;
      NetPriceAmount                 = net_price_amount;
      OrderQuantity                  = order_quantity;
      PurchaseRequisition            = purchase_requisition;
      PurchaseRequisitionItem        = purchase_requisition_item;
      BaseUnit                       = base_unit;
      MultipleAcctAssgmtDistribution = multiple_acct_assgmt_distribut;
      AccountAssignmentCategory      = account_assignment_category;
      TaxCode                        = tax_code;
      LocalCreatedBy                 = local_created_by;
      LocalCreatedAt                 = local_created_at;
      LocalLastChangedBy             = local_last_changed_by;
      LocalLastChangedAt             = local_last_changed_at;
      LastChangedAt                  = last_changed_at;
    }
}

define behavior for ZEXED_I_UP_PDCMP_A alias PurchaseOrderItemAccAssign
persistent table zexed_up_pdcmp_a
draft table zexed_up_pdc_a_d
lock dependent by _File
authorization dependent by _File
etag master LastChangedAt
{
  update;
  internal delete;

  field ( numbering : managed, readonly ) UUID;

  field ( readonly ) FileUUID, ParentUUID;
  field ( readonly : update ) PurchaseOrder, Item, AccountAssignmentNumber;

  association _Item { with draft; }
  association _File { with draft; }

  mapping for zexed_up_pdcmp_a
    {
      UUID                           = uuid;
      ParentUUID                     = parent_uuid;
      FileUUID                       = file_uuid;
      PurchaseOrder                  = purchase_order;
      Item                           = item;
      AccountAssignmentNumber        = account_assignment_number;
      CostCenter                     = cost_center;
      ProjectNetwork                 = proj_network;
      NetworkActivity                = network_activity;
      OrderQuantityUnit              = order_quantity_unit;
      Quantity                       = quantity;
      DocumentCurrency               = document_currency;
      PurgDocNetAmount               = purg_doc_net_amount;
      MultipleAcctAssgmtDistrPercent = mult_acct_assgmt_distr_percent;
      GLAccount                      = glaccount;
      LocalCreatedBy                 = local_created_by;
      LocalCreatedAt                 = local_created_at;
      LocalLastChangedBy             = local_last_changed_by;
      LocalLastChangedAt             = local_last_changed_at;
      LastChangedAt                  = last_changed_at;
    }
}