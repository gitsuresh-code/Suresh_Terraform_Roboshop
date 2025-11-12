/* module "components" {
    source = "../../terraform-roboshop-component"
    component = var.component
    rule_priority = var.rule_priority
}
 */
module "components" {
    for_each = var.components
    source = "../common_code/component"
    component = each.key
    rule_priority = each.value.rule_priority
}