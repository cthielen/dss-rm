module AdSync
  require 'active_directory'
  AD_PEOPLE_SETTINGS = YAML.load_file("#{Rails.root.to_s}/config/database.yml")['ad_people']
  AD_GROUPS_SETTINGS = YAML.load_file("#{Rails.root.to_s}/config/database.yml")['ad_groups']
  
  # Takes loginid as a string (e.g. 'jsmith') and returns an ActiveDirectory::User object
  def AdSync.fetch_user(loginid)
    settings = {
        :host => AD_PEOPLE_SETTINGS['host'],
        :base => AD_PEOPLE_SETTINGS['base'],
        :port => 636,
        :encryption => :simple_tls,
        :auth => {
          :method => :simple,
          :username => AD_PEOPLE_SETTINGS['user'],
          :password => AD_PEOPLE_SETTINGS['pass']
        }
    }

    ActiveDirectory::Base.setup(settings)
    ActiveDirectory::User.find(:first, :samaccountname => loginid)
  end

  # Takes name as a string (e.g. 'this-that') and returns an ActiveDirectory::Group object
  def AdSync.fetch_group(group_name)
    settings = {
        :host => AD_GROUPS_SETTINGS['host'],
        :base => AD_GROUPS_SETTINGS['base'],
        :port => 636,
        :encryption => :simple_tls,
        :auth => {
          :method => :simple,
          :username => AD_GROUPS_SETTINGS['user'],
          :password => AD_GROUPS_SETTINGS['pass']
        }
    }

    ActiveDirectory::Base.setup(settings)
    ActiveDirectory::Group.find(:first, :cn => group_name)
  end
  
  # Takes user as an ActiveDirectory::User object and group as a string (e.g. 'SOME-GROUP') and returns boolean
  def AdSync.add_user_to_group(user, group_name)
    settings = {
        :host => AD_GROUPS_SETTINGS['host'],
        :base => AD_GROUPS_SETTINGS['base'],
        :port => 636,
        :encryption => :simple_tls,
        :auth => {
          :method => :simple,
          :username => AD_GROUPS_SETTINGS['user'],
          :password => AD_GROUPS_SETTINGS['pass']
        }
    }

    ActiveDirectory::Base.setup(settings)
    g = ActiveDirectory::Group.find(:first, :cn => group_name)

    if g.nil?
      return false
    end

    g.add user
  end
  
  # Takes group as an ActiveDirectory::Group object and returns an array of users
  def AdSync.list_group_members(group)
    settings = {
        :host => AD_PEOPLE_SETTINGS['host'],
        :base => AD_PEOPLE_SETTINGS['base'],
        :port => 636,
        :encryption => :simple_tls,
        :auth => {
          :method => :simple,
          :username => AD_PEOPLE_SETTINGS['user'],
          :password => AD_PEOPLE_SETTINGS['pass']
        }
    }

    ActiveDirectory::Base.setup(settings)
    
    group.member_users
  end
end
