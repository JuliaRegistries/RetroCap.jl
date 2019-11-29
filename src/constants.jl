const _upper_bound_A = typemax(VersionNumber)

const _upper_bound_B = VersionNumber(typemax(Base.VInt),
                                     typemax(Base.VInt),
                                     typemax(Base.VInt))

const _upper_bound_C = VersionNumber(0,
                                     typemax(Base.VInt),
                                     typemax(Base.VInt))
