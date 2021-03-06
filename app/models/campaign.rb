class Campaign < ApplicationRecord
  enum status: %i(draft sending sent)

  belongs_to :user
  has_many :campaign_contacts, dependent: :destroy
  belongs_to :segment

  validates :name, presence: true
  validates :segment, presence: true
  validates :subject, presence: true

  def as_json(_options = nil)
    sent = campaign_contacts.count
    delivered = campaign_contacts.where.not(delivered_at: nil).count
    delivered_rate = delivered / sent.to_f
    open = campaign_contacts.where.not(open_at: nil).count
    open_rate = open / delivered.to_f
    bounce = campaign_contacts.where(status: "bounce").count + campaign_contacts.where(status: "dropped").count
    bounce_rate = bounce / sent.to_f
    click = campaign_contacts.where.not(click_at: nil).count
    click_rate = click / delivered.to_f
    spamreport = campaign_contacts.where(status: "spamreport").count
    spamreport_rate = spamreport / delivered.to_f

    {
      id: id,
      name: name,
      status: status,
      created_at: created_at,
      sent_at: sent_at,
      subject: subject,
      from: from,
      content: content,
      segment: segment,
      num_of_contacts: segment.contacts.length,
      template_id: template_id,
      user: user,
      contacts: campaign_contacts.map { |campaign_contact|
        {
          contact: campaign_contact.contact,
          status: campaign_contact.status,
          created_at: campaign_contact.created_at,
          delivered_at: campaign_contact.delivered_at,
          open_at: campaign_contact.open_at,
          click_at: campaign_contact.click_at,
        }
      },
      sent: sent,
      delivered: delivered,
      delivered_rate: delivered_rate.round(4),
      open: open,
      open_rate: open_rate.round(4),
      click: click,
      click_rate: click_rate.round(4),
      bounce: bounce,
      bounce_rate: bounce_rate.round(4),
      spamreport: spamreport,
      spamreport_rate: spamreport_rate.round(4),
    }
  end

  def send_test
    fromAddress = SendGrid::Email.new(email: ENV["EMAIL_FROM"], name: user.name)
    body = SendGrid::Content.new(type: "text/html", value: content)
    sg = SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"])
    to = SendGrid::Email.new(email: user.email)
    mail = SendGrid::Mail.new(fromAddress, subject, to, body)
    mail.reply_to = SendGrid::Email.new(email: from, name: user.name)
    sg.client.mail._("send").post(request_body: mail.to_json)
  end

  def send_to_segment
    if status === "draft"
      fromAddress = SendGrid::Email.new(email: ENV["EMAIL_FROM"], name: user.name)
      sg = SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"])

      segment.contacts.each { |contact|
        value = Mustache.render(content, name: contact.name)
        body = SendGrid::Content.new(type: "text/html", value: value)
        campaign_contact = campaign_contacts.create(contact: contact)
        to = SendGrid::Email.new(email: contact.email)
        mail = SendGrid::Mail.new(fromAddress, subject, to, body)
        mail.reply_to = SendGrid::Email.new(email: from, name: user.name)
        mail.add_custom_arg(SendGrid::CustomArg.new(key: "campaign_contact_id", value: campaign_contact.id))
        sg.client.mail._("send").post(request_body: mail.to_json)
      }

      update(status: :sent)
      update(sent_at: Time.current)
    end
  end
end
