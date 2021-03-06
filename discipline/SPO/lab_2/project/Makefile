APP = date

OBJDIR = obj
BINDIR = bin

SRCS := $(shell find . -name '*.c')
SRCDIRS := $(shell find . -name '*.c' -exec dirname {} \; | uniq)
OBJS := $(patsubst %.c,$(OBJDIR)/%.o,$(SRCS))
DEPS := $(patsubst %.c,$(OBJDIR)/%.d,$(SRCS))

DEBUG = -g
INCLUDES = -I./include
CFLAGS = $(DEBUG) -Wall $(INCLUDES) -c
LDFLAGS =
LIBS =

DEPENDS = -MT $@ -MD -MP -MF $(subst .o,.d,$@)

SHELL = /bin/bash

.PHONY: all clean distclean


all: buildrepo $(APP)

$(APP): $(OBJS)
	$(CC) $(LDFLAGS) $^ $(LIBS) -o $(addprefix $(BINDIR)/, $@)

$(OBJDIR)/%.o: %.c
	$(CC) $(CFLAGS) $(DEPENDS) $< -o $@

clean:
	$(RM) -r $(OBJDIR)

distclean: clean
	$(RM) $(APP)

buildrepo:
	@$(call make-repo)

define make-repo
for dir in $(SRCDIRS); \
do \
mkdir -p $(OBJDIR)/$$dir; \
done
endef

ifneq "$(MAKECMDGOALS)" "distclean"
ifneq "$(MAKECMDGOALS)" "clean"
-include $(DEPS)
endif
endif
