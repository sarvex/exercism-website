class CreateOnboardingNotificationsJob < ApplicationJob
  queue_as :background

  OnboardingEmail = Struct.new(:day, :slug, keyword_init: true) do
    def notification_type
      "onboarding_#{slug}".to_sym
    end
  end

  # 0 would be immediately after signing up
  # 1 is a day after signing up, etc
  #
  # Each slug should be paired with a User::Notifications::Onboarding{$SLUG}Notification class
  EMAILS = {
    1 => :community,
    3 => :fundraising
  }.map { |day, slug| OnboardingEmail.new(day:, slug:) }.freeze

  # For each email we get all the users that signed up between
  # n days ago and n+safety_offset days ago.
  # So for example, for a day 3 email, if SAFETY_OFFSET is 1,
  # we check anyone that signed up between days 3 and 4.
  #
  # This gives us a security blanket that if our scripts don't
  # run for a period of time, no-one gets missed. But after the safety
  # period we don't end up spamming old users. All onboarding notifications
  # only send once, so this is safe to run multiple times.
  SAFETY_OFFSET = 1

  private_constant :EMAILS, :SAFETY_OFFSET, :OnboardingEmail

  def perform
    I18n.backend.send(:init_translations)

    EMAILS.each do |email|
      users = User.where('created_at < ?', Time.current - email.day.days).
        where('created_at > ?', Time.current - (email.day + SAFETY_OFFSET).days)

      users.find_each do |user|
        send_email(user, email)
      rescue StandardError => e
        Bugsnag.notify(e)
      end
    end
  end

  private
  def send_email(user, email)
    has_notification = I18n.backend.send(:translations)[:en][:notifications][email.notification_type].present?

    if has_notification
      User::Notification::Create.(user, email.notification_type)
    else
      User::Notification::CreateEmailOnly.(user, email.notification_type)
    end
  end
end
