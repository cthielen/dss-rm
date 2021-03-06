require 'test_helper'

class GroupRuleResultSetTest < ActiveSupport::TestCase
  test 'destroying the last GroupRule to use a GroupRuleResultSet destroys the GroupRuleResultSet' do
    # Ensure a group has a rule
    group = entities(:groupWithNothing)

    assert group.rules.empty?, 'looks like groupWithNothing has a rule'

    group_rule = GroupRulesService.add_group_rule(group, 'loginid', 'is', 'casuser2')

    group.reload
    group_rule.reload

    assert group.rules.empty? == false, 'group should have rules'
    assert group_rule.result_set.present?, 'group_rule should have a result_set'

    result_set_id = group_rule.result_set.id

    assert GroupRuleResultSet.find_by_id(result_set_id).present?, 'rule set should exist'

    group.rules.destroy(group_rule)
    group.reload

    assert group.rules.empty?, 'group should have no rules'

    assert GroupRuleResultSet.find_by_id(result_set_id).nil?, 'rule set should no longer exist'
  end
end
