require 'test_helper'

class SyncTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  test 'creating person triggers add_to_system' do
    p = Person.new

    p.first = nil
    p.last = nil
    p.name = nil
    p.loginid = 'deleteme'

    Sync.reset_trigger_test_counts

    p.save!

    assert Sync.trigger_test_count(:add_to_system) == 1, 'add_to_system trigger count is wrong'
  end

  test 'removing person triggers remove_from_system' do
    p = Person.new

    p.first = nil
    p.last = nil
    p.name = nil
    p.loginid = 'deleteme'

    p.save!

    Sync.reset_trigger_test_counts

    p.destroy

    assert Sync.trigger_test_count(:remove_from_system) == 1, 'remove_from_system trigger count is wrong'
  end

  test 'deactivating person triggers remove_from_system' do
    p = entities(:casuser)
    PeopleService.set_active_status(p, true)

    Sync.reset_trigger_test_counts

    PeopleService.set_active_status(p, false)

    assert Sync.trigger_test_count(:remove_from_system) == 1, 'remove_from_system should have been triggered'
  end

  test 'deactivating person triggers necessary remove_from_role' do
    p = entities(:casuser)

    assert p.roles.count == 2, "casuser should have exactly two roles but has #{p.roles.count}"

    PeopleService.set_active_status(p, true)

    Sync.reset_trigger_test_counts

    PeopleService.set_active_status(p, false)

    assert Sync.trigger_test_count(:remove_from_role) == 2, 'remove_from_role should have been triggered twice'
  end

  test 'activating person triggers add_to_system' do
    p = entities(:casuser)

    PeopleService.set_active_status(p, false)

    Sync.reset_trigger_test_counts

    PeopleService.set_active_status(p, true)

    assert Sync.trigger_test_count(:add_to_system) == 1, 'add_to_system should have been triggered'
  end

  test 'activating person triggers necessary add_to_role' do
    p = entities(:casuser)

    assert p.roles.count == 2, "casuser should have exactly two roles but has #{p.roles.count}"

    PeopleService.set_active_status(p, false)

    Sync.reset_trigger_test_counts

    PeopleService.set_active_status(p, true)

    assert Sync.trigger_test_count(:add_to_role) == 2, 'add_to_role should have been triggered twice'
  end

  test 'adding person to group with roles trigger role sync' do
    @person = entities(:casuser)

    # Set up data and ensure it looks correct
    group = entities(:groupWithoutARole)
    role = roles(:boring_role)

    assert group.roles.empty?, 'groupWithoutARole should not have roles'
    assert group.members.empty?, 'groupWithoutARole should have no members'

    @person.role_assignments.all.each do |ra|
      RoleAssignmentsService.unassign_role_from_entity(ra)
    end
    assert @person.roles.empty?, 'casuser should have no roles'

    @person.group_memberships.all.each do |gm|
      GroupMembershipsService.remove_member_from_group(@person, gm.group)
    end
    assert @person.group_memberships.empty?, "'casuser' must not have group memberships for this test"

    Sync.reset_trigger_test_counts

    # Give the group a role
    RoleAssignmentsService.assign_role_to_entity(group, role)

    assert group.roles.length == 1, 'role assignment on group failed'
    assert @person.roles.empty?, 'no roles should have been given to the user as the group had no roles'

    Sync.reset_trigger_test_counts

    # Assign the test user to this group with no roles
    GroupMembershipsService.assign_member_to_group(@person, group)
    @person.reload
    assert @person.group_memberships.length == 1, 'unable to add test user to group'

    group.reload

    assert group.members.length == 1, 'groupWithoutARole should have casuser as its only member'

    assert @person.roles.length == 1, 'role assigned to group should have been assigned to group member'
    assert Sync.trigger_test_count(:add_to_role) == 1, 'add_to_role should have been triggered'
  end

  test 'removing person from group with roles trigger role sync' do
    @person = entities(:casuser)

    # Set up data and ensure it looks correct
    group = entities(:groupWithoutARole)
    role = roles(:boring_role)

    assert group.roles.empty?, 'groupWithoutARole should not have roles'
    assert group.members.empty?, 'groupWithoutARole should have no members'

    @person.role_assignments.all.each do |ra|
      RoleAssignmentsService.unassign_role_from_entity(ra)
    end
    assert @person.roles.empty?, 'casuser should have no roles'

    @person.group_memberships.all.each do |gm|
      GroupMembershipsService.remove_member_from_group(@person, gm.group)
    end
    assert @person.group_memberships.empty?, "'casuser' must not have group memberships for this test"

    # Assign the test user to this group with no roles
    gm = GroupMembershipsService.assign_member_to_group(@person, group)
    @person.reload
    assert @person.group_memberships.length == 1, 'unable to add test user to group'

    group.reload

    assert group.members.length == 1, 'groupWithoutARole should have casuser as its only member'

    @person.reload

    assert @person.roles.empty?, 'no roles should have been given to the user as the group had no roles'

    # Give the group a role and check that the user gets it
    RoleAssignmentsService.assign_role_to_entity(group, role)

    assert group.roles.length == 1, 'role assignment on group failed'

    @person.reload

    assert @person.roles.length == 1, 'role assigned to group should have been assigned to group member'

    Sync.reset_trigger_test_counts

    # Now remove that member from the group and ensure the user loses role
    GroupMembershipsService.remove_member_from_group(@person, group)
    group.reload

    assert group.members.empty?, 'group should have no members'
    assert group.roles.length == 1, 'group should still have one role'

    @person.reload

    assert @person.roles.empty?, 'removing person from group should have removed inherited role'

    assert Sync.trigger_test_count(:remove_from_role) == 1, "remove_from_role trigger count is incorrect (should be 1 but is #{Sync.trigger_test_count(:remove_from_role)})"
  end

  test 'assigning/unassigning role to group should not fire add/remove_to_role for inactive group member' do
    @person = entities(:casuser)

    # Set up data and ensure it looks correct
    group = entities(:groupWithoutARole)
    role = roles(:boring_role)

    assert group.roles.empty?, 'groupWithoutARole should have no roles'
    assert group.members.empty?, 'groupWithoutARole should have no members'

    @person.role_assignments.all.each do |ra|
      RoleAssignmentsService.unassign_role_from_entity(ra)
    end
    assert @person.roles.empty?, 'casuser should have no roles'

    @person.group_memberships.all.each do |gm|
      GroupMembershipsService.remove_member_from_group(@person, gm.group)
    end
    assert @person.group_memberships.empty?, 'casuser should have no group memberships'

    Sync.reset_trigger_test_counts

    # Assign the test user to this group with no roles
    GroupMembershipsService.assign_member_to_group(@person, group)
    @person.reload
    assert @person.group_memberships.length == 1, 'unable to add test user to group'

    group.reload

    assert group.members.length == 1, 'groupWithoutARole should have casuser as its only member'

    @person.reload

    assert @person.roles.empty?, 'no roles should have been given to the user as the group had no roles'

    PeopleService.set_active_status(@person, false)
    @person.reload

    # Give the group a role and check that the user gets it
    RoleAssignmentsService.assign_role_to_entity(group, role)

    assert group.roles.length == 1, 'role assignment on group failed'

    @person.reload

    assert @person.roles.length == 1, 'role assigned to group should have been assigned to group member'

    assert Sync.trigger_test_count(:add_to_role).zero?, 'add_to_role trigger count incorrect'
  end

  test 'assigning person to role triggers sync' do
    p = entities(:casuser)
    r = roles(:boring_role)

    assert p.roles.include?(r) == false, 'casuser should not have boring_role at the start of the test'

    Sync.reset_trigger_test_counts
    RoleAssignmentsService.assign_role_to_entity(p, r)

    assert Sync.trigger_test_count(:add_to_role) == 1, 'add_to_role should have been triggered'
  end

  test 'removing person from role triggers sync' do
    p = entities(:casuser)
    r = roles(:boring_role)

    assert p.roles.include?(r) == false, 'casuser should not have boring_role at the start of the test'
    ra = RoleAssignmentsService.assign_role_to_entity(p, r)

    Sync.reset_trigger_test_counts

    RoleAssignmentsService.unassign_role_from_entity(ra)

    assert Sync.trigger_test_count(:remove_from_role) == 1, 'remove_from_role should have been triggered'
  end

  test 'adding group to role with pre-existing group members triggers sync' do
    @person = entities(:casuser)

    # Set up data and ensure it looks correct
    group = entities(:groupWithoutARole)
    role = roles(:boring_role)

    assert group.roles.empty?, 'groupWithoutARole should not have roles'
    assert group.members.empty?, 'groupWithoutARole should have no members'

    @person.role_assignments.all.each do |ra|
      RoleAssignmentsService.unassign_role_from_entity(ra)
    end
    assert @person.roles.empty?, 'casuser should have no roles'

    @person.group_memberships.all.each do |gm|
      GroupMembershipsService.remove_member_from_group(@person, gm.group)
    end
    assert @person.group_memberships.empty?, "'casuser' must not have group memberships for this test"

    # Assign the test user to this group with no roles
    GroupMembershipsService.assign_member_to_group(@person, group)
    @person.reload
    assert @person.group_memberships.length == 1, 'unable to add test user to group'

    group.reload

    assert group.members.length == 1, 'groupWithoutARole should have casuser as its only member'

    @person.reload

    assert @person.roles.empty?, 'no roles should have been given to the user as the group had no roles'

    Sync.reset_trigger_test_counts

    # Give the group a role and check that the user gets it
    RoleAssignmentsService.assign_role_to_entity(group, role)

    assert group.roles.length == 1, 'role assignment on group failed'

    @person.reload

    assert @person.roles.length == 1, 'role assigned to group should have been assigned to group member'
    assert Sync.trigger_test_count(:add_to_role) == 1, 'add_to_role should have been triggered'
  end

  test 'removing group from role with group members triggers sync' do
    @person = entities(:casuser)

    # Set up data and ensure it looks correct
    group = entities(:groupWithoutARole)
    role = roles(:boring_role)

    assert group.roles.empty?, 'groupWithoutARole should not have roles'
    assert group.members.empty?, 'groupWithoutARole should have no members'

    @person.role_assignments.all.each do |ra|
      RoleAssignmentsService.unassign_role_from_entity(ra)
    end
    assert @person.roles.empty?, 'casuser should have no roles'

    @person.group_memberships.all.each do |gm|
      GroupMembershipsService.remove_member_from_group(@person, gm.group)
    end
    assert @person.group_memberships.empty?, "'casuser' must not have group memberships for this test"

    # Assign the test user to this group with no roles
    GroupMembershipsService.assign_member_to_group(@person, group)
    @person.reload
    assert @person.group_memberships.length == 1, 'unable to add test user to group'

    group.reload

    assert group.members.length == 1, 'groupWithoutARole should have casuser as its only member'

    @person.reload

    assert @person.roles.empty?, 'no roles should have been given to the user as the group had no roles'

    # Give the group a role and check that the user gets it
    RoleAssignmentsService.assign_role_to_entity(group, role)

    assert group.roles.length == 1, 'role assignment on group failed'

    @person.reload

    assert @person.roles.length == 1, 'role assigned to group should have been assigned to group member'

    Sync.reset_trigger_test_counts

    # Now remove that role from the group and ensure the user loses it
    RoleAssignmentsService.unassign_role_from_entity(group.role_assignments[0])
    group.reload

    assert group.roles.empty?, 'role removal on group failed'

    @person.reload
    assert @person.roles.empty?, 'role removed from group should have been removed from group member'

    assert Sync.trigger_test_count(:remove_from_role) == 1, 'remove_from_role trigger count is incorrect'
  end

  test 'deleting role triggers sync' do
    p = entities(:casuser)

    assert p.roles.count == 2, "casuser should have exactly two roles but has #{p.roles.count}"
    assert p.roles[0].members.length == 2, 'role should have 2 members'

    Sync.reset_trigger_test_counts
    RolesService.destroy_role(p.roles[0])

    assert Sync.trigger_test_count(:remove_from_role) == 2, "remove_from_role should have been triggered twice but was triggered #{Sync.trigger_test_count(:remove_from_role)}"
  end

  # FIXME: This test needs to account for the while_managing_calculated_memberships_for() changes
  test 'person attribute modification resulting in removal from automatic group triggers sync' do
    group = entities(:groupWithNothing)
    role = roles(:really_boring_role)

    assert group.roles.empty?, 'looks like groupWithNothing has a role'
    assert group.rules.empty?, 'looks like groupWithNothing has a rule'
    assert group.owners.empty?, 'looks like groupWithNothing has an owner'
    assert group.operators.empty?, 'looks like groupWithNothing has an operator'

    @person = entities(:casuser)

    SisAssociationsService.add_sis_association_to_person(@person, Major.find_by(name: 'History'), 1, 'GR')

    # Test basic rule creation matches existing people
    assert group.members.empty?, 'group should have no members'
    GroupRulesService.add_group_rule(group, 'major', 'is', 'History')
    group.reload
    assert group.members.length == 1, 'group should have 1 member(s)'

    assert group.roles.length == 0, 'group should have no roles'
    assert @person.roles.include?(role) == false, 'person should not have really_boring_role'

    test_sync_trigger(:add_to_role) do
      RoleAssignmentsService.assign_role_to_entity(group, role)
      assert group.roles.length == 1, 'group should have a role'
      @person.reload
      assert @person.roles.include?(role), 'person should have really_boring_role'
    end

    # Subtract a second from the 'updated_at' flag to ensure it is a reliable
    # indicator of a group being touched
    group.updated_at -= 1
    group.save!
    group_last_updated_at = group.updated_at

    # Remove matching characteristic
    test_sync_trigger(:remove_from_role) do
      assert @person.roles.include?(role), 'person should have really_boring_role'
      GroupRulesService.while_managing_calculated_memberships_for(@person) do
        SisAssociationsService.remove_sis_association_from_person(@person, @person.sis_associations[0])
      end
      group.reload
      assert group.members.empty?, 'group should have no members'
      assert group.updated_at > group_last_updated_at, 'affected group should have been touched'
      @person.reload
      assert @person.roles.include?(role) == false, 'person should not have really_boring_role'
    end
  end

  test 'person attribute modification resulting in addition to automatic group triggers sync' do
    group = entities(:groupWithNothing)
    role = roles(:really_boring_role)

    assert group.roles.empty?, 'looks like groupWithNothing has a role'
    assert group.rules.empty?, 'looks like groupWithNothing has a rule'
    assert group.owners.empty?, 'looks like groupWithNothing has an owner'
    assert group.operators.empty?, 'looks like groupWithNothing has an operator'

    @person = entities(:casuser)

    # Test basic rule creation matches existing people
    assert group.members.empty?, 'group should have no members'
    GroupRulesService.add_group_rule(group, 'major', 'is', 'History')
    group.reload
    assert group.members.empty?, 'group should have no members'

    assert group.roles.length == 0, 'group should have no roles'
    assert @person.roles.include?(role) == false, 'person should not have really_boring_role'

    test_sync_trigger(:add_to_role, 0) do
      RoleAssignmentsService.assign_role_to_entity(group, role)
      assert group.roles.length == 1, 'group should have a role'
      @person.reload
      assert @person.roles.include?(role) == false, 'person should not have really_boring_role'
    end

    # Subtract a second from the 'updated_at' flag to ensure it is a reliable
    # indicator of a group being touched
    group.updated_at -= 1
    group.save!
    group_last_updated_at = group.updated_at

    # Add matching characteristic
    test_sync_trigger(:add_to_role) do
      GroupRulesService.while_managing_calculated_memberships_for(@person) do
        SisAssociationsService.add_sis_association_to_person(@person, Major.find_by(name: 'History'), 1, 'GR')
      end
      group.reload
      assert group.members.length == 1, 'group should have a member'
      assert group.updated_at > group_last_updated_at, 'affected group should have been touched'
      @person.reload
      assert @person.roles.include?(role), 'person should have really_boring_role'
    end
  end

  test 'removing a group rule causing member loss triggers sync' do
    group = entities(:groupWithNothing)
    role = roles(:really_boring_role)

    assert group.roles.empty?, 'looks like groupWithNothing has a role'
    assert group.rules.empty?, 'looks like groupWithNothing has a rule'
    assert group.owners.empty?, 'looks like groupWithNothing has an owner'
    assert group.operators.empty?, 'looks like groupWithNothing has an operator'

    @person = entities(:casuser)

    SisAssociationsService.add_sis_association_to_person(@person, Major.find_by(name: 'History'), 1, 'GR')

    # Test basic rule creation matches existing people
    assert group.members.empty?, 'group should have no members'
    GroupRulesService.add_group_rule_and_sync_members_roles(group, 'major', 'is', 'History')
    group.reload
    assert group.members.length == 1, 'group should have 1 member(s)'

    assert group.roles.length == 0, 'group should have no roles'
    assert @person.roles.include?(role) == false, 'person should not have really_boring_role'

    test_sync_trigger(:add_to_role) do
      RoleAssignmentsService.assign_role_to_entity(group, role)
      assert group.roles.length == 1, 'group should have a role'
      @person.reload
      assert @person.roles.include?(role), 'person should have really_boring_role'
    end

    # Subtract a second from the 'updated_at' flag to ensure it is a reliable
    # indicator of a group being touched
    group.updated_at -= 1
    group.save!
    group_last_updated_at = group.updated_at

    # Remove matching characteristic
    test_sync_trigger(:remove_from_role) do
      Rails.logger.debug "CALLING IT"
      GroupRulesService.remove_group_rule_and_sync_members_roles(group.rules.first)
      Rails.logger.debug "DONE CALLING IT"
      group.reload
      assert group.members.empty?, 'group should have no members'
      assert group.updated_at > group_last_updated_at, 'affected group should have been touched'
      assert group.rules.empty?, 'group should have no rules'
      @person.reload
      assert @person.roles.include?(role) == false, 'person should not have really_boring_role'
    end
  end

  private

  # Generic function for testing a sync trigger.
  def test_sync_trigger(sync_type, expected_sync_count = 1)
    Sync.reset_trigger_test_counts
    yield
    assert Sync.trigger_test_count(sync_type) == expected_sync_count, "#{sync_type} should have been triggered #{expected_sync_count} time(s) but was triggered #{Sync.trigger_test_count(sync_type)} time(s)"
  end
end
