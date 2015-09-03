module ActiveFedora::File::Attributes

  def mime_type
    fetch_mime_type
  end

  def mime_type=(value)
    metadata.mime_type = value
  end

  def original_name
    @original_name ||= fetch_original_name
  end

  def original_name= name
    @original_name = name
  end

  def digest
    response = metadata.ldp_source.graph.query(predicate: RDF::Vocab::PREMIS.hasMessageDigest)
    # fallback on old predicate for checksum
    response = metadata.ldp_source.graph.query(predicate: RDF::Vocab::Fcrepo4.digest) if response.empty?
    response.map(&:object)
  end

  def persisted_size
    ldp_source.head.headers['Content-Length'].to_i unless new_record?
  end

  def dirty_size
    content.size if content_changed? && content.respond_to?(:size)
  end

  def size
    dirty_size || persisted_size
  end

  def has_content?
    size && size > 0
  end

  def empty?
    !has_content?
  end

  private

    def links
      @links ||= Ldp::Response.links(ldp_source.head)
    end

    def default_mime_type
      'text/plain'
    end

    def fetch_mime_type
      return default_mime_type if new_record? && metadata.mime_type.blank?
      metadata.mime_type.first
    end

    def fetch_original_name
      return if new_record?
      m = ldp_source.head.headers['Content-Disposition'].match(/filename="(?<filename>[^"]*)";/)
      URI.decode(m[:filename])
    end

end
