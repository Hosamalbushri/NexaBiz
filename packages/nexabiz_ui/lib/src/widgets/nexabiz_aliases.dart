import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import 'app_button.dart';
import 'app_card.dart';
import 'app_checkbox.dart';
import 'app_data_table.dart';
import 'app_date_field.dart';
import 'app_confirmation_dialog.dart';
import 'app_dialog.dart';
import 'app_empty_state.dart';
import 'app_error_state.dart';
import 'app_form.dart';
import 'app_form_actions.dart';
import 'app_form_dialog.dart';
import 'app_icon_button.dart';
import 'app_loading.dart';
import 'app_select_field.dart';
import 'app_status_badge.dart';
import 'app_surface.dart';
import 'app_switch.dart';
import 'app_text_field.dart';
import 'app_tree.dart';

/// Canonical NexaBiz Design System component aliases.
///
/// These aliases expose standard NexaBiz-prefixed component names
/// as the application-level design system public API.

typedef NexaBizDialog<T> = AppDialog<T>;
typedef NexaBizDialogSize = AppDialogSize;
typedef NexaBizConfirmationDialog = AppConfirmationDialog;
typedef NexaBizFormDialog<T> = AppFormDialog<T>;

typedef NexaBizForm = AppForm;
typedef NexaBizFormSection = AppFormSection;
typedef NexaBizFormActions = AppFormActions;

typedef NexaBizButton = AppButton;
typedef NexaBizButtonVariant = AppButtonVariant;

typedef NexaBizIconButton = AppIconButton;
typedef NexaBizIconButtonVariant = AppIconButtonVariant;

typedef NexaBizSurface = AppSurface;
typedef NexaBizSurfaceVariant = AppSurfaceVariant;

typedef NexaBizTextField = AppTextField;

typedef NexaBizSelectField<T> = AppSelectField<T>;
typedef NexaBizSelectItem<T> = AppSelectItem<T>;

typedef NexaBizCheckbox = AppCheckbox;

typedef NexaBizSwitch = AppSwitch;

typedef NexaBizCard = AppCard;

typedef NexaBizLoading = AppLoading;
typedef NexaBizLoadingStyle = AppLoadingStyle;

typedef NexaBizEmptyState = AppEmptyState;

typedef NexaBizErrorState = AppErrorState;

typedef NexaBizStatusBadge = AppStatusBadge;

typedef NexaBizDateField = AppDateField;

typedef NexaBizDataTable<T> = AppDataTable<T>;

typedef NexaBizTree<T> = AppTree<T>;
typedef NexaBizTreeNodeRow<T> = AppTreeNodeRow<T>;
typedef NexaBizTreeNode<T> = shadcn.TreeNode<T>;
typedef NexaBizTreeItemNode<T> = shadcn.TreeItemNode<T>;
typedef NexaBizTreeRootNode<T> = shadcn.TreeRootNode<T>;
typedef NexaBizBranchLine = shadcn.BranchLine;


/// Dialog helper aliases.
final showNexaBizDialog = AppDialog.show;
